# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # Checks expectations on `current_url` that bypass Capybara's waiting.
        #
        # `have_current_path` can match full URLs and waits for navigation.
        # A regexp needs `url: true` so it matches the full URL, not just the
        # path. Autocorrection is unsafe because URL parsing and waiting change
        # comparison behavior.
        # Dynamic `match` patterns and `include`, `start_with`, and `end_with`
        # are reported without autocorrection.
        #
        # @example
        #   # bad
        #   expect(page.current_url).to eq('https://example.com/login')
        #   expect(current_url).to match(%r{/login})
        #   expect(current_url).to match('login')
        #   expect(page.current_url).to include('/login')
        #
        #   # good
        #   expect(page).to have_current_path('https://example.com/login')
        #   expect(page).to have_current_path(%r{/login}, url: true)
        #   expect(page).to have_current_path(/login/, url: true)
        #
        class CurrentUrlExpectation < RuboCop::Cop::Base
          extend AutoCorrector

          MSG = 'Use `have_current_path` on `page` to wait for the URL.'
          RESTRICT_ON_SEND = %i[expect].freeze
          PATH_MATCHERS = {
            to: 'have_current_path',
            not_to: 'have_no_current_path',
            to_not: 'have_no_current_path'
          }.freeze

          # @!method url_actual(node)
          def_node_matcher :url_actual, <<~PATTERN
            (send nil? :expect
              $(send {(send nil? :page) nil?} :current_url))
          PATTERN

          # @!method supported_matcher?(node)
          def_node_matcher :supported_matcher?, <<~PATTERN
            {(send nil? :eq _)
             (send nil? :match _)
             (send nil? {:include :start_with :end_with} (str _))}
          PATTERN

          # @!method expectation_runner?(node)
          def_node_matcher :expectation_runner?, <<~PATTERN
            (send (send nil? :expect _) {:to :not_to :to_not} _)
          PATTERN

          def self.autocorrect_incompatible_with
            [Style::TrailingCommaInArguments]
          end

          def on_send(node)
            actual = url_actual(node)
            return unless actual

            runner = node.parent
            return unless expectation_runner?(runner)

            matcher = runner.first_argument
            return unless supported_matcher?(matcher)

            register_offense(node.loc.selector, actual, runner, matcher)
          end
          alias on_csend on_send

          private

          def register_offense(range, actual, runner, matcher)
            regexp = if matcher.method?(:match)
                       regexp_source(matcher.first_argument)
                     end
            unless correctable_matcher?(matcher, regexp)
              return add_offense(range)
            end

            add_offense(range) do |corrector|
              autocorrect(corrector, actual, runner, matcher, regexp)
            end
          end

          def correctable_matcher?(matcher, regexp)
            return true if matcher.method?(:eq)
            return false unless matcher.method?(:match)

            matcher.first_argument.regexp_type? || regexp
          end

          def regexp_source(argument)
            Regexp.new(argument.value).inspect if argument.str_type?
          rescue RegexpError
            nil
          end

          def autocorrect(corrector, actual, runner, matcher, regexp)
            corrector.replace(actual, 'page')
            unless runner.method?(:to)
              corrector.replace(runner.loc.selector, 'to')
            end
            corrector.replace(matcher.loc.selector,
                              PATH_MATCHERS.fetch(runner.method_name))
            return unless matcher.method?(:match)

            corrector.replace(matcher.first_argument, regexp) if regexp
            corrector.insert_after(matcher.first_argument, ', url: true')
          end
        end
      end
    end
  end
end
