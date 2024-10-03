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
        def initialize(stdout)
          super
          require "factory_bot"
          ::FactoryBot.find_definitions
          ::FactoryBot.factories.each(&:compile)
        end

        def name = FactoryBot::ADDON_NAME

        def execute(request, params)
          case request.to_sym
          when :factories
            collection = FactoryHandler.new.execute(params)
          when :traits
            collection = TraitHandler.new.execute(params)
          when :attributes
            collection = AttributeHandler.new.execute(params)
          end

          write_response({ result: collection })
        end
      end
    end
  end
end
