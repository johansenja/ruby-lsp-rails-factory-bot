# frozen_string_literal: true

require_relative "base_handler"

module RubyLsp
  module Rails
    module FactoryBot
      class ServerAddon < RubyLsp::Rails::ServerAddon
        # Handler for fetching and serialising traits
        class AttributeHandler < BaseHandler
          private

          def fetch(params)
            factory = ::FactoryBot.factories[params[:factory_name]]
            name = params[:name]

            attributes = factory.definition.declarations.select do |attr|
              name.nil? || name.empty? ? true : attr.name.to_s.include?(name)
            end
            model_class = factory.send :class_name

            return attributes, model_class
          rescue KeyError
            # FactoryBot throws a KeyError if the factory isn't found, so nothing to do here
          end

          def serialise(attributes, model_class)
            attributes.map do |attribute|
              source_location = block_for(attribute)&.source_location
              {
                name: attribute.name,
                owner: model_class.name,
                type: guess_attribute_type(attribute, model_class),
                source_location: source_location,
                source: block_source(attribute),
              }
            end
          end

          def guess_attribute_type(attribute, model_class)
            if model_class.respond_to? :attribute_types
              type = model_class.attribute_types[attribute.name.to_s]
              return nil if type.nil?

              return ACTIVE_MODEL_TYPE_TO_RUBY_TYPE[type.class] || type.type
            end

            return unless model_class.respond_to? :reflections

            association = model_class.reflections[attribute.name.to_s]

            association&.klass
          end

          ACTIVE_MODEL_TYPE_TO_RUBY_TYPE = {
            ActiveModel::Type::String => "String",
            ActiveModel::Type::ImmutableString => "String",
            ActiveModel::Type::Float => "Float",
            ActiveModel::Type::Integer => "Integer",
            ActiveModel::Type::Boolean => "boolean",
            ActiveModel::Type::Date => "Date",
            ActiveModel::Type::Time => "Time",
            ActiveModel::Type::DateTime => "DateTime",
          }.freeze
        end
      end
    end
  end
end
