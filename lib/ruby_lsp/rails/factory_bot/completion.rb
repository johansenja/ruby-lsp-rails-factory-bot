# frozen_string_literal: true

require "ruby_lsp/internal"

module RubyLsp
  module Rails
    module FactoryBot
      class Completion
        include RubyLsp::Requests::Support::Common

        # TODO: Avoid duplication with other class
        FACTORY_BOT_METHODS = %i[
          create
          build
          build_stubbed
          attributes_for
        ].flat_map { |attr| [attr, :"#{attr}_list", :"#{attr}_pair"] }.freeze

        def initialize(response_builder, node_context, dispatcher, server_client)
          @response_builder = response_builder
          @node_context = node_context
          @server_client = server_client

          dispatcher.register self, :on_call_node_enter
        end

        def on_call_node_enter(node)
          return unless FACTORY_BOT_METHODS.include?(node.name) ||
                        FACTORY_BOT_METHODS.include?(@node_context.parent.name)

          case node.arguments
          in [Prism::SymbolNode => factory_name_node]
            handle_factory(factory_name_node, factory_name_node.value.to_s)

          in [Prism::SymbolNode => factory_name_node, *, Prism::SymbolNode => trait_node]
            handle_trait(factory_name_node.value.to_s, node, trait_node.value.to_s)

          in [Prism::SymbolNode => factory_name_node, *, Prism::CallNode => call_node]
            handle_attribute(factory_name_node.value.to_s, node, call_node.message)

          in [Prism::SymbolNode => factory_name_node, *, Prism::KeywordHashNode => kw_node]
            handle_attribute(
              factory_name_node.value.to_s, node, kw_node.elements.last.key.value&.to_s
            )
          in [Prism::SymbolNode => factory_name_node, *, Prism::HashNode => hash_node]
            handle_attribute(
              factory_name_node.value.to_s, node, hash_node.elements.last.key.value&.to_s
            )
          else
            $stderr.write node.arguments
            nil
          end
        rescue => e
          $stderr.write(e, e.backtrace)
        end

        private

        def handle_attribute(factory_name, node, value = "")
          @server_client.get_attributes(factory_name: factory_name, name: value)&.each do |attr|
            $stderr.write "attribute", attr
            label_details = Interface::CompletionItemLabelDetails.new(
              description: attr[:type],
            )
            range = range_from_node(node)

            @response_builder << Interface::CompletionItem.new(
              label: attr[:name],
              filter_text: attr[:name],
              label_details: label_details,
              text_edit: Interface::TextEdit.new(range: range, new_text: attr[:name]),
              kind: Constant::CompletionItemKind::PROPERTY,
              data: {
                owner_name: attr[:owner],
                guessed_type: attr[:owner], # the type of the owner, not the attribute
              },
            )
          end
        end

        def handle_trait(factory_name, node, value = "")
          @server_client.get_traits(factory_name: factory_name, name: value)&.each do |tr|
            $stderr.write "trait", tr
            label_details = Interface::CompletionItemLabelDetails.new(
              description: tr[:owner],
            )
            range = range_from_node(node)

            name = tr[:name]

            @response_builder << Interface::CompletionItem.new(
              label: name,
              filter_text: name,
              label_details: label_details,
              text_edit: Interface::TextEdit.new(range: range, new_text: name),
              kind: Constant::CompletionItemKind::PROPERTY,
              data: {
                owner_name: nil,
                guessed_type: tr[:owner] # the type of the owner
              },
            )
          end
        end

        def handle_factory(node, name)
          @server_client.get_factories(name: name)&.each do |fact|
            $stderr.write "factory", fact
            @response_builder << Interface::CompletionItem.new(
              label: fact[:name],
              filter_text: fact[:name],
              label_details: Interface::CompletionItemLabelDetails.new(
                description: fact[:model_class]
              ),
              text_edit: Interface::TextEdit.new(
                range: range_from_node(node),
                new_text: fact[:name],
              ),
              kind: Constant::CompletionItemKind::CLASS,
              data: {
                guessed_type: fact[:model_class]
              }
            )
          end
        end
      end
    end
  end
end
