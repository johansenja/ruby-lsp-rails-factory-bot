# frozen_string_literal: true

module RubyLsp
  module Rails
    module FactoryBot
      class IndexingEnhancement < RubyIndexer::Enhancement
        class FactoryBotFactory < RubyIndexer::Entry
          def initialize(name, *rest)
            super("#{name}-factory", *rest)
          end
        end

        def initialize(...)
          super
          @inside_factory_bot_dot_define = false
          @index = @listener.instance_variable_get(:@index)
          @uri = @listener.instance_variable_get(:@uri)
        end

        def on_call_node_enter(node)
          case node.message
          when "define"
            @inside_factory_bot_dot_define = true
          when "factory"
            handle_factory_definition(node) if @inside_factory_bot_dot_define
          end
        end

        def on_call_node_leave(node)
          return unless node.message == "define"

          @inside_factory_bot_dot_define = false
        end

        private

        def handle_factory_definition(node)
          args = node.arguments&.arguments
          return unless args

          case args
          in [Prism::SymbolNode => _factory_name_node, *]
            @index.add(
              FactoryBotFactory.new(
                "#{_factory_name_node.value}__FACTORY", @uri, _factory_name_node.location, collect_comments(node),
              ),
            )
          else
            nil
          end
        end
      end
    end
  end
end
