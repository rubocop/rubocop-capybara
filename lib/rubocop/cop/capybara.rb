# frozen_string_literal: true

require_relative 'capybara/rspec'

module RuboCop
  module Cop
    # Cops for the `Capybara` department. The department's cops are
    # registered for lazy loading and their files are loaded on demand.
    module Capybara
      extend LazyLoader

      register_cop :AmbiguousClick, "#{__dir__}/capybara/ambiguous_click"
      register_cop :AssertStyle, "#{__dir__}/capybara/assert_style"
      register_cop :FindAllFirst, "#{__dir__}/capybara/find_all_first"
      register_cop :ModalMethodWithoutBlock, "#{__dir__}/capybara/modal_method_without_block"
      register_cop :RedundantWithinFind, "#{__dir__}/capybara/redundant_within_find"
      register_cop :SpecificActions, "#{__dir__}/capybara/specific_actions"
      register_cop :SpecificFinders, "#{__dir__}/capybara/specific_finders"
    end
  end
end
