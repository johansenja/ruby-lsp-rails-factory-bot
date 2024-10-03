# frozen_string_literal: true

require_relative "base_handler"

module RubyLsp
  module Rails
    module FactoryBot
      class ServerAddon < RubyLsp::Rails::ServerAddon
        # Handler for fetching and serialising traits
        class TraitHandler < BaseHandler
          private

          def fetch(params)
            factory = ::FactoryBot.factories[params[:factory_name]]

            trait_name_partial = params[:name]
            defined_traits = defined_traits(factory, trait_name_partial)
            internal_traits = internal_traits(factory.send(:class_name), trait_name_partial)

            defined_traits.concat(internal_traits)
          rescue KeyError
            # FactoryBot throws a KeyError if the factory isn't found, so nothing to do here
          end

          def defined_traits(factory, trait_name_partial)
            factory.defined_traits.select { |tr| tr.name.to_s.include? trait_name_partial }
          end

          def internal_traits(factory_class_name, trait_name_partial)
            ::FactoryBot::Internal.traits.select do |tr|
              (tr.klass == factory_class_name || !tr.klass) && tr.name.to_s.include?(trait_name_partial)
            end
          end

          def serialise(traits)
            traits.map do |tr|
              source_location = block_for(tr)&.source_location
              {
                name: tr.name,
                source_location: source_location,
                source: block_source(tr),
                owner: tr.klass,
              }
            end
          end
        end
      end
    end
  end
end
