# frozen_string_literal: true

require "sorbet-runtime"
require "ruby_lsp/addon"
require "ruby_lsp/rails/factory_bot/hover"
require "ruby_lsp/ruby_lsp_rails/runner_client"
require "ruby_lsp/rails/factory_bot"

RSpec.describe RubyLsp::Rails::FactoryBot::Hover do
  let(:dispatcher) { Prism::Dispatcher.new }
  let(:program_node) { Prism.parse(code).value }
  let(:call_node) { program_node.statements.body.first }
  let(:parent_node) { call_node }
  let(:nesting_nodes) { [] }
  let(:node_context) { RubyLsp::NodeContext.new(node, parent_node, nesting_nodes, call_node) }
  let(:response_builder) { [] }
  let(:server_client) { RubyLsp::Rails::NullClient.new }
  let(:ruby_index) { RubyIndexer::Index.new }

  subject { described_class.new(response_builder, node_context, dispatcher, server_client, ruby_index) }

  describe "#on_symbol_node_enter" do
    context "for attributes" do
      let(:code) { "create :user, :with_email, :with_name, age: 19" }
      let(:node) { call_node.arguments.arguments[3].elements.first.key } # age:

      it "provides a tooltip" do
        allow(server_client).to receive(:delegate_request).and_return([{ name: "age", type: "Integer" }])

        subject.on_symbol_node_enter(node)
        expect(response_builder).to eq [
          "age", { category: :title },
          "Integer", { category: :documentation },
        ]
      end

      context "for create_list" do
        let(:code) { "create_list :user, 2, :with_email, :with_name, age: 19" }
        let(:node) { call_node.arguments.arguments[4].elements.first.key } # age:

        it "provides a tooltip" do
          allow(server_client).to receive(:delegate_request).and_return([{ name: "age", type: "Integer" }])

          subject.on_symbol_node_enter(node)
          expect(response_builder).to eq [
            "age", { category: :title },
            "Integer", { category: :documentation },
          ]
        end
      end
    end

    context "for factories" do
      let(:code) { "create :user, :with_email, :with_name, age: 19" }
      let(:node) { call_node.arguments.arguments[0] } # :user

      it "provides a tooltip" do
        allow(server_client).to receive(:delegate_request).and_return([{ name: "user", model_class: "User" }])

        subject.on_symbol_node_enter(node)
        expect(response_builder).to eq [
          "user", { category: :title },
          "User", { category: :documentation },
        ]
      end

      context "for create_list" do
        let(:code) { "create_list :user, 2, :with_email, :with_name, age: 19" }
        let(:node) { call_node.arguments.arguments[0] } # :user

        it "provides a tooltip" do
          allow(server_client).to receive(:delegate_request).and_return([{ name: "user", model_class: "User" }])

          subject.on_symbol_node_enter(node)
          expect(response_builder).to eq [
            "user", { category: :title },
            "User", { category: :documentation },
          ]
        end
      end
    end

    context "for traits" do
      let(:code) { "create :user, :with_email, :with_name, age: 19" }
      let(:node) { call_node.arguments.arguments[2] } # :with_name

      it "provides a tooltip for a trait without source" do
        allow(server_client).to receive(:delegate_request).and_return([{ name: "with_name" }])

        subject.on_symbol_node_enter(node)
        expect(response_builder).to eq [
          "with_name", { category: :title },
          "trait of user", { category: :documentation },
        ]
      end

      it "provides a tooltip for a trait with source" do
        allow(server_client).to receive(:delegate_request).and_return(
          [{ name: "with_name", source: "with_name { name { 'Geoff' } }", source_location: ["/foo.rb", 2] }],
        )

        subject.on_symbol_node_enter(node)
        expect(response_builder).to eq [
          "with_name", { category: :title },
          "```ruby\nwith_name { name { 'Geoff' } }\n```", { category: :documentation },
          "[Definition](file:///foo.rb#L2)", { category: :links },
        ]
      end

      context "for create_list" do
        let(:code) { "create_list :user, 2, :with_email, :with_name, age: 19" }
        let(:node) { call_node.arguments.arguments[3] } # :with_name

        it "provides a tooltip" do
          allow(server_client).to receive(:delegate_request).and_return([{ name: "with_name" }])

          subject.on_symbol_node_enter(node)
          expect(response_builder).to eq [
            "with_name", { category: :title },
            "trait of user", { category: :documentation },
          ]
        end
      end
    end

    context "for irrelevant methods" do
      let(:code) { "puts :user, age: 19" }
      let(:node) { call_node.arguments.arguments[0] }

      it "doesn't provide a tooltip" do
        subject.on_symbol_node_enter(node)
        expect(response_builder).to be_empty
      end
    end
  end
end
