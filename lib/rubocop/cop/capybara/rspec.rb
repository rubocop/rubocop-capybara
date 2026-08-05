# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Cops for the `Capybara/RSpec` department. The department's cops are
      # registered for lazy loading and their files are loaded on demand.
      module RSpec
        extend LazyLoader

        register_cop :CurrentPathExpectation, "#{__dir__}/rspec/current_path_expectation"
        register_cop :HaveContent, "#{__dir__}/rspec/have_content"
        register_cop :HaveSelector, "#{__dir__}/rspec/have_selector"
        register_cop :MatchStyle, "#{__dir__}/rspec/match_style"
        register_cop :NegationMatcher, "#{__dir__}/rspec/negation_matcher"
        register_cop :NegationMatcherAfterVisit, "#{__dir__}/rspec/negation_matcher_after_visit"
        register_cop :PredicateMatcher, "#{__dir__}/rspec/predicate_matcher"
        register_cop :SpecificMatcher, "#{__dir__}/rspec/specific_matcher"
        register_cop :VisibilityMatcher, "#{__dir__}/rspec/visibility_matcher"
      end
    end
  end
end
