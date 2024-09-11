# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp_rails/runner_client"

require_relative "completion"
require_relative "hover"
require_relative "server_extension"

module RubyLsp
  module Rails
    module FactoryBot
      class Addon < ::RubyLsp::Addon
        def activate(global_state, *)
          @ruby_index = global_state.index
        end

        def deactivate(*); end

        def name
          "ruby-lsp-rails-factory-bot"
        end

        def create_completion_listener(response_builder, node_context, dispatcher, uri)
          path = uri.to_standardized_path
          return unless path&.end_with?("_test.rb") || path&.end_with?("_spec.rb")
          return unless factory_bot_call_args?(node_context)

          Completion.new(response_builder, node_context, dispatcher, RubyLsp::Rails::RunnerClient.instance)
        end

        def create_hover_listener(response_builder, node_context, dispatcher)
          # TODO: need URI param
          Hover.new(response_builder, node_context, dispatcher, RubyLsp::Rails::RunnerClient.instance, @ruby_index)
        end

        def workspace_did_change_watched_files(changes)
          return unless changes.any? do |change|
            change[:uri].match?(/(?:spec|test).+factor.+\.rb/)
          end

          RubyLsp::Rails::RunnerClient.instance.trigger_reload
        end

        private

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
