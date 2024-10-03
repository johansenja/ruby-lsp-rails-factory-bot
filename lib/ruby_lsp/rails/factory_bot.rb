# frozen_string_literal: true

module RubyLsp
  module Rails
    module FactoryBot
      FACTORY_BOT_METHODS = %i[
        create
        build
        build_stubbed
        attributes_for
      ].flat_map { |attr| [attr, :"#{attr}_list", :"#{attr}_pair"] }.freeze
    end
  end
end
