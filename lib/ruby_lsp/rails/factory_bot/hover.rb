# frozen_string_literal: true

require "ruby_lsp/internal"

require_relative "addon_name"

module RubyLsp
  module Rails
    module FactoryBot
      # Hover listener - calls the registered methods when the appropriate nodes are entered
      class Hover
        include RubyLsp::Requests::Support::Common

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
          unless parent.is_a?(Prism::CallNode) || FactoryBot::FACTORY_BOT_METHODS.include?(call_node.message.to_sym)
            return
          end

          process_arguments_pattern(symbol_node, call_node.arguments.arguments)
        end

        private

        def process_arguments_pattern(symbol_node, arguments) # rubocop:disable Metrics/MethodLength
          case arguments
          in [^symbol_node, *]
            handle_factory(symbol_node)
          in [Prism::SymbolNode => _factory_node, *, ^symbol_node] |
             [Prism::SymbolNode => _factory_node, *, ^symbol_node, Prism::KeywordHashNode] |
             [Prism::SymbolNode => _factory_node, *, ^symbol_node, Prism::HashNode] |
             [Prism::SymbolNode => _factory_node, ^symbol_node, *] |
             [Prism::SymbolNode => _factory_node, Prism::IntegerNode, ^symbol_node, *] |
             [Prism::SymbolNode => _factory_node, Prism::IntegerNode, *, ^symbol_node, Prism::KeywordHashNode] |
             [Prism::SymbolNode => _factory_node, Prism::IntegerNode, *, ^symbol_node, Prism::HashNode]

            handle_trait(symbol_node, _factory_node)

          in [Prism::SymbolNode => _factory_node, *, Prism::KeywordHashNode => _kw_hash] |
             [Prism::SymbolNode => _factory_node, *, Prism::HashNode => _kw_hash]

            handle_attribute(symbol_node, _factory_node) if _kw_hash.elements.any? { |e| e.key == symbol_node }
          else
            nil
          end
        end

        def build_response(title, documentation, link)
          @response_builder.push(title, category: :title) if title
          @response_builder.push(documentation, category: :documentation) if documentation
          @response_builder.push(link, category: :links) if link
        end

        def handle_attribute(symbol_node, factory_node)
          name = symbol_node.value.to_s
          attribute = make_request(
            :attributes,
            factory_name: factory_node.value.to_s, name: name,
          )&.find { |attr| attr[:name] == name }

          return unless attribute

          build_response(attribute[:name].to_s, attribute[:type].to_s, link_location(attribute[:source_location]))
        end

        def factory_documentation(factory)
          index_entry = @ruby_index.first_unqualified_const(factory[:name])
          return markdown_from_index_entries(factory[:model_class], index_entry) if index_entry

          factory[:model_class].to_s
        end

        def handle_factory(symbol_node)
          name = symbol_node.value.to_s
          factory = make_request(:factories, name: name)&.find { |f| f[:name] == name }
          return unless factory

          factory_index_definition = @ruby_index["#{factory[:name]}__FACTORY"]&.first
          if factory_index_definition
            loc = factory_index_definition.location
            location =
              "#{factory_index_definition.uri}#L#{loc.start_line},#{loc.start_column}-#{loc.end_line},#{loc.end_column}"
          end

          build_response(factory[:name], factory_documentation(factory), location)
        end

        def trait_tooltip(trait, factory_name)
          source = trait[:source]&.length&.positive? ? trait[:source] : nil
          source ? "```ruby\n#{source}\n```" : "trait of #{trait[:owner] || factory_name}"
        end

        def handle_trait(symbol_node, factory_node)
          factory_name = factory_node.value.to_s
          trait_name = symbol_node.value.to_s

          trait = make_request(:traits, factory_name: factory_name, name: trait_name)&.find do |tr|
            tr[:name] == trait_name
          end

          return unless trait

          build_response(trait[:name], trait_tooltip(trait, factory_name), link_location(trait[:source_location]))
        end

        def make_request(request_name, **params)
          @server_client.delegate_request(
            server_addon_name: FactoryBot::ADDON_NAME,
            request_name: request_name.to_s,
            **params,
          )
        end

        def link_location(source_location)
          return unless source_location

          return if source_location.empty?

          "[Definition](#{URI::Generic.from_path(path: source_location[0])}#L#{source_location[1]})"
        end
      end
    end
  end
end
