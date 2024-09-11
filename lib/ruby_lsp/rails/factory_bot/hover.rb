# frozen_string_literal: true

require "ruby_lsp/internal"

module RubyLsp
  module Rails
    module FactoryBot
      class Hover
        include RubyLsp::Requests::Support::Common

        # TODO: Avoid duplication with other class
        FACTORY_BOT_METHODS = %i[
          create
          build
          build_stubbed
          attributes_for
        ].flat_map { |attr| [attr, :"#{attr}_list", :"#{attr}_pair"] }.freeze

        def initialize(response_builder, node_context, dispatcher, server_client, ruby_index)
          @response_builder = response_builder
          @node_context = node_context
          @server_client = server_client
          @ruby_index = ruby_index

          dispatcher.register self, :on_symbol_node_enter
        end

        def on_symbol_node_enter(symbol_node)
          parent = @node_context.parent
          call_node = @node_context.call_node

          return unless call_node

          # "parent" isn't strictly speaking the immediate parent as in the AST - the
          # element it refers to is a bit opinionated... in this case, it is always the call node,
          # whether the symbol is an argument in the call_node args, or a symbol in a kw hash :/
          unless parent.is_a?(Prism::CallNode) || FACTORY_BOT_METHODS.include?(call_node.message.to_sym)
            return
          end

          case call_node.arguments.arguments
          in [^symbol_node, *]
            handle_factory(symbol_node)
          in [Prism::SymbolNode => factory_node, *, ^symbol_node]
            handle_trait(symbol_node, factory_node)
          in [Prism::SymbolNode => factory_node, ^symbol_node, *]
            handle_trait(symbol_node, factory_node)
          in [Prism::SymbolNode => factory_node, Integer, ^symbol_node, *]
            handle_trait(symbol_node, factory_node)
          in [Prism::SymbolNode => factory_node, *, Prism::KeywordHashNode => kw_hash] if kw_hash.elements.any? { |e| e.key == symbol_node }
            handle_attribute(symbol_node, factory_node)
          in [Prism::SymbolNode => factory_node, *, Prism::HashNode => kw_hash] if kw_hash.elements.any? { |e| e.key == symbol_node }
            handle_attribute(symbol_node, factory_node)
          else
            $stderr.write "nope fact_or_trait", call_node.arguments.arguments
            nil
          end
        end

        private

        def handle_attribute(symbol_node, factory_node)
          name = symbol_node.value.to_s
          attribute = @server_client.get_attributes(
            factory_name: factory_node.value.to_s, name: name
          )&.find { |attr| attr[:name] == name }

          return unless attribute

          @response_builder.push(
            "#{attribute[:name]} (#{attribute[:type]})",
            category: :documentation
          )
        end

        def handle_factory(symbol_node)
          name = symbol_node.value.to_s

          factory = @server_client.get_factories(name: name)&.find { |f| f[:name] == name }

          return unless factory

          index_entry = @ruby_index.first_unqualified_const(factory[:name])

          if index_entry
            @response_builder.push(
              markdown_from_index_entries(
                factory[:model_class],
                index_entry
              ),
              category: :documentation
            )
          else
            @response_builder.push(
              "#{factory[:name]} (#{factory[:model_class]})",
              category: :documentation
            )
          end
        end

        def handle_trait(symbol_node, factory_node)
          factory_name = factory_node.value.to_s
          trait_name = symbol_node.value.to_s

          trait = @server_client.get_traits(
            factory_name: factory_name, name: trait_name
          )&.find { |tr| tr[:name] == trait_name }

          return unless trait

          @response_builder.push(
            "#{trait[:name]} (trait of #{trait[:owner] || factory_name})",
            category: :documentation
          )
        end
      end
    end
  end
end
