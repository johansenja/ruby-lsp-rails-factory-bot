# frozen_string_literal: true

require "sorbet-runtime"
require "ruby_lsp/addon"
require "ruby_lsp/ruby_lsp_factory_bot/completion"
require "factory_bot"

FactoryBot.define do
  factory :company do
    address { "" }
  end

  factory :config do
    theme { "light" }
  end

  factory :corporation do
    name { "foo" }
  end

  factory :user do
    age { 23 }

    trait :with_email do
      email { "name@example.com" }
    end

    trait :with_name do
      name { "Geoff" }
    end
  end

  factory :enterprise do
    trading_name { "ACME corp" }
    headquarters
  end
end

RSpec.describe RubyLsp::FactoryBot::Completion do
  let(:dispatcher) { Prism::Dispatcher.new }
  let(:program_node) { Prism.parse(code).value }
  let(:call_node) { program_node.statements.body.first }
  let(:parent_node) { nil }
  let(:nesting_nodes) { [] }
  let(:node_context) { RubyLsp::NodeContext.new(node, parent_node, nesting_nodes, call_node) }
  let(:response_builder) { [] }

  subject { described_class.new(response_builder, node_context, dispatcher) }

  describe "#on_symbol_node_enter" do
    before(:each) do
      expect(call_node).to be_a(Prism::CallNode).or be_nil
      expect(response_builder).to be_empty
    end

    context "for incomplete factory names" do
      let(:code) { "create :c" }
      let(:node) { call_node.arguments.arguments.first }

      it "provides completion for factory names" do
        subject.on_symbol_node_enter(node)
        expect(response_builder.map(&:label)).to eq %w[:company :config :corporation]
        expect(response_builder.length).to eq 3
      end
    end

    context "for incomplete traits" do
      let(:code) { "create :user, :with_e" }
      let(:node) { call_node.arguments.arguments[1] }

      it "provides completion" do
        subject.on_symbol_node_enter(node)
        expect(response_builder.first.label).to eq ":with_email"
        expect(response_builder.length).to eq 1
      end
    end

    context "for multiple traits" do
      let(:code) { "create :user, :with_email, :with_n" }
      let(:node) { call_node.arguments.arguments[2] }

      it "provides completion" do
        subject.on_symbol_node_enter(node)
        expect(response_builder.first.label).to eq ":with_name"
        expect(response_builder.length).to eq 1
      end
    end

    context "for irrelevant methods" do
      let(:code) { "puts :b" }
      let(:node) { call_node.arguments.arguments[0] }

      it "doesn't provide completion" do
        subject.on_symbol_node_enter(node)
        expect(response_builder).to be_empty
      end
    end

    context "for irrelevant methods" do
      let(:code) { ":foo" }
      let(:node) { program_node.statements.body.first }
      let(:call_node) { nil }

      it "doesn't provide completion" do
        subject.on_keyword_hash_node_enter(node)
        expect(response_builder).to be_empty
      end
    end
  end

  describe "#on_keyword_hash_node_enter" do
    # context "for complete attributes" do
    #   let(:code) { "create :enterprise, trading_name: 'abc'" }
    #   let(:node) { call_node.arguments.arguments[1] }

    #   it "provides completion" do
    #     subject.on_keyword_hash_node_enter(node)
    #     expect(response_builder.first.label).to eq ":headquarters"
    #   end
    # end

    context "for irrelevant methods" do
      let(:code) { "puts a: b" }
      let(:node) { call_node.arguments.arguments[0] }

      it "doesn't provide completion" do
        subject.on_keyword_hash_node_enter(node)
        expect(response_builder).to be_empty
      end
    end
  end

  describe "#on_call_node_enter" do
    context "for incomplete attributes" do
      let(:code) { "create :user, :with_email, :with_name, a" }
      let(:node) { call_node.arguments.arguments[3] }

      it "provides completion" do
        subject.on_call_node_enter(node)
        expect(response_builder.first.label).to eq ":age"
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

  describe "#on_hash_node_enter" do
    context "for hash attributes" do
      let(:code) { "create :enterprise, { " }
      let(:node) { call_node.arguments.arguments[1] }

      it "provides completion" do
        subject.on_hash_node_enter(node)
        expect(response_builder.map(&:label)).to eq %w[:trading_name :headquarters]
        expect(response_builder.length).to eq 2
      end
    end

    context "for irrelevant methods" do
      let(:code) { "puts({a: b})" }
      let(:node) { call_node.arguments.arguments[0] }

      it "doesn't provide completion" do
        subject.on_hash_node_enter(node)
        expect(response_builder).to be_empty
      end
    end
  end
end
