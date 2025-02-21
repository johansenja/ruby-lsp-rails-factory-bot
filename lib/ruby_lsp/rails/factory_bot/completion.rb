# frozen_string_literal: true

require "ruby_lsp/internal"

require_relative "addon_name"

module RubyLsp
  module Rails
    module FactoryBot
      # The listener that is created when the user requests autocomplete at the relevant time.
      class Completion # rubocop:disable Metrics/ClassLength
        include RubyLsp::Requests::Support::Common

        def initialize(response_builder, node_context, dispatcher, server_client)
          @response_builder = response_builder
          @node_context = node_context
          @server_client = server_client

          dispatcher.register self, :on_call_node_enter
        end

        def on_call_node_enter(node)
          call_node = @node_context.call_node
          return unless call_node

          return unless FactoryBot::FACTORY_BOT_METHODS.include?(call_node.name)

          process_arguments_pattern(node, call_node.arguments&.arguments)
        rescue StandardError => e
          $stderr.write(e, e.backtrace)
        end

        private

        def process_arguments_pattern(node, arguments) # rubocop:disable Metrics/MethodLength
          case arguments
          in [Prism::SymbolNode => factory_name_node]
            handle_factory(factory_name_node, node_string_value(factory_name_node))

          in [Prism::SymbolNode => factory_name_node, *, Prism::SymbolNode => trait_node]
            already_used_traits = gather_already_used_traits(arguments)
            handle_trait(
              node_string_value(factory_name_node), node, already_used_traits, node_string_value(trait_node),
            )

          in [Prism::SymbolNode => _factory_name_node, *, Prism::KeywordHashNode => _kw_node] |
            [Prism::SymbolNode => _factory_name_node, *, Prism::HashNode => _kw_node] |
            [Prism::SymbolNode => _factory_name_node, *, Prism::CallNode => _call_node]

            attr_name = node_string_value(_call_node || _kw_node.elements.last.key)
            already_used_attrs = gather_already_used_attrs(_kw_node)
            handle_attribute(node_string_value(_factory_name_node), node, already_used_attrs, attr_name)
          else
            nil
          end
        end

        def node_string_value(node)
          case node
          when Prism::CallNode
            node.name.to_s
          when Prism::SymbolNode
            node.value.to_s
          when nil
            ""
          end
        end

        def gather_already_used_attrs(kw_node)
          attrs = Set.new
          return attrs unless kw_node

          kw_node.elements.each do |e|
            attrs.add(node_string_value(e.key))
          end

          attrs
        end

        def handle_attribute(factory_name, node, already_used_attrs, value = "")
          range = range_from_node(node)
          make_request(:attributes, factory_name: factory_name, name: value)&.each do |attr|
            next if already_used_attrs.member?(attr[:name].to_s)

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

        def gather_already_used_traits(arguments)
          trait_names = Set.new
          # skip the first one because it's factory name
          1.upto(arguments.length - 1) do |i|
            arg = arguments[i]
            next if arg.is_a?(Prism::IntegerNode)
            break unless arg.is_a?(Prism::SymbolNode)

            trait_names.add(arg.value.to_s)
          end
          trait_names
        end

        def handle_trait(factory_name, node, already_used_traits, value = "")
          make_request(:traits, factory_name: factory_name, name: value)&.each do |tr|
            next if already_used_traits.member?(tr[:name].to_s)

            label_details = Interface::CompletionItemLabelDetails.new(description: tr[:owner])
            range = range_from_node(node)
            name = tr[:name]

            @response_builder << serialise_trait(name, range, label_details, tr[:owner])
          end
        end

        def serialise_trait(name, range, label_details, owner)
          Interface::CompletionItem.new(
            label: name,
            filter_text: name,
            label_details: label_details,
            text_edit: Interface::TextEdit.new(range: range, new_text: name),
            kind: Constant::CompletionItemKind::PROPERTY,
            data: { owner_name: nil, guessed_type: owner },
          )
        end

        def handle_factory(node, name)
          range = range_from_node(node)
          make_request(:factories, name: name)&.each do |fact|
            @response_builder << serialise_factory(fact[:name], fact[:model_class], range)
          end
        end

        def make_request(request_name, **params)
          @server_client.delegate_request(
            server_addon_name: FactoryBot::ADDON_NAME,
            request_name: request_name.to_s,
            **params,
          )
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
      end
    end
  end
end
