# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/ruby_lsp_rails/runner_client"

require_relative "completion"
require_relative "hover"
require_relative "addon_name"
require_relative "../factory_bot"

module RubyLsp
  module Rails
    module FactoryBot
      # The addon to be registered with ruby-lsp. See https://shopify.github.io/ruby-lsp/add-ons.html
      class Addon < ::RubyLsp::Addon
        def activate(global_state, *)
          runner_client.register_server_addon(File.expand_path("server_addon.rb", __dir__))

          @ruby_index = global_state.index
        end

        def deactivate(*); end

        def name
          FactoryBot::ADDON_NAME
        end

        def create_completion_listener(response_builder, node_context, dispatcher, uri)
          path = uri.to_standardized_path
          return unless path&.end_with?("_test.rb") || path&.end_with?("_spec.rb")
          return unless factory_bot_call_args?(node_context)

          Completion.new(response_builder, node_context, dispatcher, runner_client)
        end

        def create_hover_listener(response_builder, node_context, dispatcher)
          # TODO: need URI param
          Hover.new(response_builder, node_context, dispatcher, runner_client, @ruby_index)
        end

        def workspace_did_change_watched_files(changes)
          return unless changes.any? do |change|
            change[:uri].match?(/(?:spec|test).+factor.+\.rb/)
          end

          runner_client.trigger_reload
        end

        private

        def runner_client
          @rails_addon ||= ::RubyLsp::Addon.get("Ruby LSP Rails")
          @rails_addon.rails_runner_client
        end

        FACTORY_BOT_METHODS = %i[
          create
          build
          build_stubbed
          attributes_for
        ].flat_map { |attr| [attr, :"#{attr}_list", :"#{attr}_pair"] }.freeze

        def factory_bot_call_args?(node_context)
          node_context.call_node && FACTORY_BOT_METHODS.include?(node_context.call_node.name)
          true
        end
      end
    end
  end
end
