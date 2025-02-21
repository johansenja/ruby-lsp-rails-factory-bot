# frozen_string_literal: true

require "ruby_lsp/addon"
require "ruby_lsp/ruby_lsp_rails/addon"

require_relative "completion"
require_relative "hover"
require_relative "definition"
require_relative "addon_name"
require_relative "../factory_bot"
require_relative "../../../ruby_lsp_rails_factory_bot"

module RubyLsp
  module Rails
    module FactoryBot
      # The addon to be registered with ruby-lsp. See https://shopify.github.io/ruby-lsp/add-ons.html
      class Addon < ::RubyLsp::Addon
        def activate(global_state, outgoing_queue)
          @ruby_index = global_state.index

          @outgoing_queue = outgoing_queue
          log "Activating #{name} add-on v#{VERSION}"
        end

        def deactivate(*); end

        def name
          FactoryBot::ADDON_NAME
        end

        def create_completion_listener(response_builder, node_context, dispatcher, _uri)
          register_addon!
          Completion.new(response_builder, node_context, dispatcher, runner_client)
        end

        def create_hover_listener(response_builder, node_context, dispatcher)
          register_addon!
          Hover.new(response_builder, node_context, dispatcher, runner_client, @ruby_index)
        end

        def create_definition_listener(response_builder, _uri, node_context, dispatcher)
          register_addon!
          Definition.new(response_builder, node_context, dispatcher, runner_client)
        end

        def workspace_did_change_watched_files(changes)
          return unless changes.any? do |change|
            change[:uri].match?(/(?:spec|test).+factor.+\.rb/)
          end

          runner_client.trigger_reload
        end

        private

        # the addon must be registered as a rails server addon once the server has booted
        def register_addon!
          @addon_registered ||= # rubocop:disable Naming/MemoizedInstanceVariableName
            begin
              addon_path = File.expand_path("server_addon.rb", __dir__)
              runner_client.register_server_addon(addon_path)
              true
            end
        end

        def runner_client
          @rails_addon ||= ::RubyLsp::Addon.get(
            "Ruby LSP Rails",
            ::RubyLsp::Rails::FactoryBot::REQUIRED_RUBY_LSP_RAILS_VERSION,
          )
          @rails_addon.rails_runner_client
        end

        def log(msg)
          return if !@outgoing_queue || @outgoing_queue.closed?

          @outgoing_queue << Notification.window_log_message(msg)
        end
      end
    end
  end
end
