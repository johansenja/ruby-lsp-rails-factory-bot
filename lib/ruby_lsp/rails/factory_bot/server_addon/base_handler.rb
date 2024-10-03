# frozen_string_literal: true

module RubyLsp
  module Rails
    module FactoryBot
      class ServerAddon < RubyLsp::Rails::ServerAddon
        # Common handler functionality
        class BaseHandler
          def execute(params)
            collection, *rest = fetch(params)

            serialise(collection, *rest) if collection
          end

          private

          def fetch(_params) = throw("Not implemented")

          def serialise(_collection, *) = throw("Not implemented")

          # helper - might be best to live elsewhere?
          def block_for(attr)
            attr.instance_variable_get :@block
          end

          # helper - might be best to live elsewhere?
          def block_source(attr)
            blk = block_for(attr)
            blk.source if blk.respond_to? :source
          end
        end
      end
    end
  end
end
