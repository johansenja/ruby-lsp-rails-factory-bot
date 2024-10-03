# frozen_string_literal: true

require "sorbet-runtime"
require "ruby_lsp/addon"
require "ruby_lsp/rails/factory_bot/completion"
require "ruby_lsp/ruby_lsp_rails/runner_client"
require "ruby_lsp/rails/factory_bot"

RSpec.describe RubyLsp::Rails::FactoryBot::Completion do
  let(:dispatcher) { Prism::Dispatcher.new }
  let(:program_node) { Prism.parse(code).value }
  let(:call_node) { program_node.statements.body.first }
  let(:parent_node) { call_node }
  let(:nesting_nodes) { [] }
  let(:node_context) { RubyLsp::NodeContext.new(node, parent_node, nesting_nodes, call_node) }
  let(:response_builder) { [] }
  let(:server_client) { RubyLsp::Rails::NullClient.new }

  subject { described_class.new(response_builder, node_context, dispatcher, server_client) }

  describe "#on_call_node_enter" do
    context "for incomplete attributes" do
      let(:code) { "create :user, :with_email, :with_name, a" }
      let(:node) { call_node }

      it "provides completion" do
        allow(server_client).to receive(:make_request).and_return({ result: [{ name: "age" }] })

        subject.on_call_node_enter(node)
        expect(response_builder.first.label).to eq "age"
        expect(response_builder.length).to eq 1
      end
    end

    context "for irrelevant methods" do
      let(:code) { "puts a" }
      let(:node) { call_node.arguments.arguments[0] }

      it "doesn't provide completion" do
        subject.on_call_node_enter(node)
        expect(response_builder).to be_empty
      end
    end
  end
end
