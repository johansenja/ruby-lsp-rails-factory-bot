# frozen_string_literal: true

require_relative "addon_name"
require_relative "server_addon/factory_handler"
require_relative "server_addon/trait_handler"
require_relative "server_addon/attribute_handler"

module RubyLsp
  module Rails
    module FactoryBot
      # The addon for the ruby-lsp-rails server runtime
      class ServerAddon < RubyLsp::Rails::ServerAddon
        def initialize(stdout, stderr, capabilities)
          super

          # TODO: move to before_start hook
          with_progress "ruby-lsp-rails-factory-bot-1", "initialisation" do
            require "factory_bot"
            ::FactoryBot.find_definitions
            ::FactoryBot.factories.each(&:compile)
          end
        end

        def name = FactoryBot::ADDON_NAME

        def execute(request, params) # rubocop:disable Metrics/MethodLength
          case request.to_sym
          when :factories
            collection = FactoryHandler.new.execute(params)
          when :traits
            collection = TraitHandler.new.execute(params)
          when :attributes
            collection = AttributeHandler.new.execute(params)
          else
            return send_error_response("#{request} no supported")
          end

          send_result(collection || [])
        rescue => e # rubocop:disable Style/RescueStandardError
          send_error_response("An error occurred while fetching #{request} - #{e}")
        end
      end
    end
  end
end
