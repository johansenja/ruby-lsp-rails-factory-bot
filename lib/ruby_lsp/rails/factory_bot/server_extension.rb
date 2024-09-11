# frozen_string_literal: true

require "ruby_lsp_rails/server/extension"

module RubyLsp
  module Rails
    module FactoryBot
      class ServerExtension < RubyLsp::Rails::Server::Extension

        before_start do
          require "factory_bot"
          ::FactoryBot.find_definitions
          ::FactoryBot.factories.each(&:compile)
        end

        after_reload do
          ::FactoryBot.find_definitions
          ::FactoryBot.factories.each(&:compile)
        end

        command :factories do |params|
          name = params[:name]
          factories = ::FactoryBot.factories.select do |f|
            name.nil? || name.empty? ? true : f.name.to_s.include?(params[:name])
          end

          factories.map do |fact|
            model_class = fact.send :class_name
            case model_class
            when String, Symbol
              model_class = model_class.to_s.camelize
            end
            {
              name: fact.name,
              model_class: model_class,
            }
          end
        end

        command :traits do |params|
          factory = ::FactoryBot.factories[params[:factory_name]]

          trait_name_partial = params[:name]
          traits = factory.defined_traits.select { |tr| tr.name.to_s.include? trait_name_partial }.concat(
            ::FactoryBot::Internal.traits.select { |tr|
              (tr.klass == factory.send(:class_name) || !tr.klass) && tr.name.to_s.include?(trait_name_partial)
            }
          )

          traits.map do |tr|
            source_location = ServerExtension.block_for(tr)&.source_location
            {
              name: tr.name,
              source_location: source_location,
              source: ServerExtension.block_source(tr),
              owner: tr.klass,
            }
          end
        rescue KeyError
        end

        command :attributes do |params|
          factory = ::FactoryBot.factories[params[:factory_name]]
          name = params[:name]

          attributes = factory.definition.declarations.select { |attr|
            name.nil? || name.empty? ? true : attr.name.to_s.include?(name)
          }

          model_class = factory.send :class_name

          attributes.map do |attribute|
            source_location = ServerExtension.block_for(attribute)&.source_location
            {
              name: attribute.name,
              owner: model_class.name,
              type: ServerExtension.guess_attribute_type(attribute, model_class),
              source_location: source_location,
              source: ServerExtension.block_source(attribute),
            }
          end
        rescue KeyError
        end

        class << self
          def block_for(attr)
            attr.instance_variable_get :@block
          end

          def block_source(attr)
            blk = block_for(attr)

            blk.source if blk.respond_to? :source
          end

          def guess_attribute_type(attribute, model_class)
            if model_class.respond_to? :attribute_types
              type = model_class.attribute_types[attribute.name.to_s]

              return case type
              when nil then nil
              when ActiveModel::Type::String, ActiveModel::Type::ImmutableString
                "String"
              when ActiveModel::Type::Float
                "Float"
              when ActiveModel::Type::Integer
                "Integer"
              when ActiveModel::Type::Boolean
                "boolean"
              when ActiveModel::Type::Date
                "Date"
              when ActiveModel::Type::Time
                "Time"
              when ActiveModel::Type::DateTime
                "DateTime"
              else
                type.type
              end
            end

            return unless model_class.respond_to? :reflections

            association = model_class.reflections[attribute.name.to_s]

            association&.klass
          end
        end
      end
    end
  end
end
