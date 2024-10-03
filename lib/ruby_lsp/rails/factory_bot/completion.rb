# frozen_string_literal: true

require "ruby_lsp/internal"

require_relative "addon_name"

module RubyLsp
  module Rails
    module FactoryBot
      # The listener that is created when the user requests autocomplete at the relevant time.
      #
      # NOTE: autocompletion is only triggered on certain node types - almost exclusively call nodes
      # and constants IIRC, so you cannot currently receive autocomplete options for symbols (eg.
      # factory or trait names) :/
      class Completion
        include RubyLsp::Requests::Support::Common

        def initialize(response_builder, node_context, dispatcher, server_client)
          @response_builder = response_builder
          @node_context = node_context
          @server_client = server_client

          dispatcher.register self, :on_call_node_enter
        end

        def on_call_node_enter(node)
          return unless FactoryBot::FACTORY_BOT_METHODS.include?(node.name) ||
                        FactoryBot::FACTORY_BOT_METHODS.include?(@node_context.parent.name)

          process_arguments_pattern(node, node.arguments)
        rescue StandardError => e
          $stderr.write(e, e.backtrace)
        end

        private

        def process_arguments_pattern(node, arguments) # rubocop:disable Metrics/MethodLength
          case arguments
          in [Prism::SymbolNode => factory_name_node]
            handle_factory(factory_name_node, node_string_value(factory_name_node))

          in [Prism::SymbolNode => factory_name_node, *, Prism::SymbolNode => trait_node]
            handle_trait(node_string_value(factory_name_node), node, node_string_value(trait_node))

          in [Prism::SymbolNode => _factory_name_node, *, Prism::KeywordHashNode => _kw_node] |
            [Prism::SymbolNode => _factory_name_node, *, Prism::HashNode => _kw_node] |
            [Prism::SymbolNode => _factory_name_node, *, Prism::CallNode => _call_node]

            attr_name = _call_node ? _call_node.message : _kw_node.elements.last.key.value&.to_s
            handle_attribute(node_string_value(_factory_name_node), node, attr_name)
          else
            nil
          end
        end

        def node_string_value(node)
          node.value.to_s
        end

        def handle_attribute(factory_name, node, value = "")
          range = range_from_node(node)
          make_request(:attributes, factory_name: factory_name, name: value)&.each do |attr|
            label_details = Interface::CompletionItemLabelDetails.new(description: attr[:type])

            @response_builder << serialise_attribute(attr[:name], label_details, attr[:owner], range)
          end
        end

        def serialise_attribute(name, label_details, owner, range)
          Interface::CompletionItem.new(
            label: name,
            filter_text: name,
            label_details: label_details,
            text_edit: Interface::TextEdit.new(range: range, new_text: name),
            kind: Constant::CompletionItemKind::PROPERTY,
            data: { owner_name: owner, guessed_type: owner }, # the type of the owner, not the attribute
          )
        end

        def handle_trait(factory_name, node, value = "")
          make_request(:traits, factory_name: factory_name, name: value)&.each do |tr|
            label_details = Interface::CompletionItemLabelDetails.new(description: tr[:owner])
            range = range_from_node(node)
            name = tr[:name]

            @response_builder << serialise_trait(name, range, label_details)
          end
        end

        def serialise_trait(name, range, label_details)
          Interface::CompletionItem.new(
            label: name,
            filter_text: name,
            label_details: label_details,
            text_edit: Interface::TextEdit.new(range: range, new_text: name),
            kind: Constant::CompletionItemKind::PROPERTY,
            data: { owner_name: nil, guessed_type: tr[:owner] },
          )
        end

        def handle_factory(node, name)
          range = range_from_node(node)
          make_request(:factories, name: name)&.each do |fact|
            @response_builder << serialise_factory(fact[:name], fact[:model_class], range)
          end
        end

        def serialise_factory(name, model_class, range)
          Interface::CompletionItem.new(
            label: name,
            filter_text: name,
            label_details: Interface::CompletionItemLabelDetails.new(description: model_class),
            text_edit: Interface::TextEdit.new(range: range, new_text: name),
            kind: Constant::CompletionItemKind::CLASS,
            data: { guessed_type: model_class },
          )
        end

        def make_request(request_name, **params)
          resp = @server_client.make_request(
            "server_addon/delegate",
            server_addon_name: FactoryBot::ADDON_NAME,
            request_name: request_name,
            **params,
          )
          resp[:result] if resp
        end
      end
    end
  end
end
