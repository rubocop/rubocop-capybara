# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # Checks expectations on `page.title` that bypass Capybara's waiting.
        #
        # `have_title` waits for the expected title. Its whitespace matching
        # differs from direct String comparison, so autocorrection is unsafe.
        #
        # @example
        #   # bad
        #   expect(page.title).to eq('Dashboard')
        #   expect(page.title).to include('Dash')
        #   expect(page.title).to match(/Dash/)
        #
        #   # good
        #   expect(page).to have_title('Dashboard', exact: true)
        #   expect(page).to have_title('Dash')
        #   expect(page).to have_title(/Dash/)
        #
        class TitleExpectation < RuboCop::Cop::Base
          extend AutoCorrector

          MSG = 'Use `have_title` on `page` to wait for the title.'
          RESTRICT_ON_SEND = %i[expect].freeze
          RUNNERS = %i[to not_to to_not].freeze

          # @!method title_actual(node)
          def_node_matcher :title_actual, <<~PATTERN
            (send nil? :expect $(send (send nil? :page) :title))
          PATTERN

          # @!method supported_matcher?(node)
          def_node_matcher :supported_matcher?, <<~PATTERN
            {(send nil? {:eq :include} (str _))
             (send nil? :match (regexp ...))}
          PATTERN

          def on_send(node)
            actual = title_actual(node)
            return unless actual

            runner = node.parent
            return unless runner&.send_type? &&
              RUNNERS.include?(runner.method_name)

            matcher = runner.first_argument
            return unless supported_matcher?(matcher)

            add_offense(actual) do |corrector|
              autocorrect(corrector, actual, matcher)
            end
          end
          alias on_csend on_send

          private

          def autocorrect(corrector, actual, matcher)
            corrector.replace(actual, 'page')
            corrector.replace(matcher.loc.selector, 'have_title')
            return unless matcher.method?(:eq)

            corrector.insert_after(matcher.first_argument, ', exact: true')
          end
        end
      end
    end
  end
end
