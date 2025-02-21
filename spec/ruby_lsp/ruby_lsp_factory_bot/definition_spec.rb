# frozen_string_literal: true

require "sorbet-runtime"
require "ruby_lsp/addon"
require "ruby_lsp/rails/factory_bot/definition"
require "ruby_lsp/ruby_lsp_rails/runner_client"
require "ruby_lsp/ruby_lsp_rails/support/location_builder"
require "ruby_lsp/rails/factory_bot"

RSpec.describe RubyLsp::Rails::FactoryBot::Definition do
  let(:dispatcher) { Prism::Dispatcher.new }
  let(:program_node) { Prism.parse(code).value }
  let(:call_node) { program_node.statements.body.first }
  let(:parent_node) { call_node }
  let(:nesting_nodes) { [] }
  let(:node_context) { RubyLsp::NodeContext.new(node, parent_node, nesting_nodes, call_node) }
  let(:response_builder) { [] }
  let(:server_client) { RubyLsp::Rails::NullClient.new }

  subject { described_class.new(response_builder, node_context, dispatcher, server_client) }

  describe "#on_symbol_node_enter" do
    context "for attributes" do
      let(:code) { "create :user, :with_email, :with_name, age: 19" }
      let(:node) { call_node.arguments.arguments[3].elements.first.key } # age:

      it "provides a definition" do
        allow(server_client).to receive(:delegate_request).and_return(
          [{ name: "age", type: "Integer", source_location: [__FILE__, 1] }],
        )

        subject.on_symbol_node_enter(node)
        resp = response_builder[0]
        expect(resp.attributes[:uri]).to eq "file://#{__FILE__}"
        expect(resp.attributes[:range].attributes[:start].attributes[:line]).to eq 0
      end

      it "doesn't provide a definition if none given" do
        allow(server_client).to receive(:delegate_request).and_return(
          [{ name: "age", type: "Integer" }],
        )

        subject.on_symbol_node_enter(node)
        expect(response_builder).to eq []
      end

      context "for create_list" do
        let(:code) { "create_list :user, 2, :with_email, :with_name, age: 19" }
        let(:node) { call_node.arguments.arguments[4].elements.first.key } # age:

        it "provides a definition" do
          allow(server_client).to receive(:delegate_request).and_return(
            [{ name: "age", type: "Integer", source_location: [__FILE__, 2] }],
          )

          subject.on_symbol_node_enter(node)
          resp = response_builder[0]
          expect(resp.attributes[:uri]).to eq "file://#{__FILE__}"
          expect(resp.attributes[:range].attributes[:start].attributes[:line]).to eq 1
        end

        it "doesn't provide a definition if none given" do
          allow(server_client).to receive(:delegate_request).and_return(
            [{ name: "age", type: "Integer" }],
          )

          subject.on_symbol_node_enter(node)
          expect(response_builder).to eq []
        end
      end
    end

    context "for traits" do
      let(:code) { "create :user, :with_email, :with_name, age: 19" }
      let(:node) { call_node.arguments.arguments[2] } # :with_name

      it "provides a definition" do
        allow(server_client).to receive(:delegate_request).and_return(
          [{ name: "with_name", source_location: [__FILE__, 3] }],
        )

        subject.on_symbol_node_enter(node)
        resp = response_builder[0]
        expect(resp.attributes[:uri]).to eq "file://#{__FILE__}"
        expect(resp.attributes[:range].attributes[:start].attributes[:line]).to eq 2
      end

      it "doesn't provide a definition if none given" do
        allow(server_client).to receive(:delegate_request).and_return(
          [{ name: "with_name" }],
        )

        subject.on_symbol_node_enter(node)
        expect(response_builder).to eq []
      end

      context "for create_list" do
        let(:code) { "create_list :user, 2, :with_email, :with_name, age: 19" }
        let(:node) { call_node.arguments.arguments[3] } # :with_name

        it "provides a definition" do
          allow(server_client).to receive(:delegate_request).and_return(
            [{ name: "with_name", source_location: [__FILE__, 4] }],
          )

          subject.on_symbol_node_enter(node)
          resp = response_builder[0]
          expect(resp.attributes[:uri]).to eq "file://#{__FILE__}"
          expect(resp.attributes[:range].attributes[:start].attributes[:line]).to eq 3
        end

        it "doesn't provide a definition if none given" do
          allow(server_client).to receive(:delegate_request).and_return(
            [{ name: "with_name" }],
          )

          subject.on_symbol_node_enter(node)
          expect(response_builder).to eq []
        end
      end
    end

    context "for irrelevant methods" do
      let(:code) { "puts :user, age: 19" }
      let(:node) { call_node.arguments.arguments[0] }

      it "doesn't provide a definition" do
        subject.on_symbol_node_enter(node)
        expect(response_builder).to be_empty
      end
    end
  end
end
