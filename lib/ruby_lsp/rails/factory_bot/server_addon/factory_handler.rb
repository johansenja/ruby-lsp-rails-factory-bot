# frozen_string_literal: true

require_relative "base_handler"

module RubyLsp
  module Rails
    module FactoryBot
      class ServerAddon < RubyLsp::Rails::ServerAddon
        # Handler for fetching and serialising factories
        class FactoryHandler < BaseHandler
          private

          def fetch(params)
            name = params[:name]
            ::FactoryBot.factories.select do |f|
              name.nil? || name.empty? ? true : f.name.to_s.include?(params[:name])
            end
          end

          def serialise(factories)
            factories.map do |fact|
              model_class = fact.send :class_name

              case model_class
              when String, Symbol
                model_class = model_class.to_s.camelize
              end

              { name: fact.name, model_class: model_class }
            end
          end
        end
      end
    end
  end
end
