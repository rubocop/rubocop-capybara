# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # Checks for expectations on the value of an element found by Capybara.
        #
        # @safety
        #   This cop's autocorrection is unsafe because `find('input').value`
        #   checks the value of the first matched element, while `have_field`
        #   checks that any field on the page has the expected value.
        #
        # @example
        #   # bad
        #   expect(find('input').value).to eq('foobar')
        #   expect(find(:css, 'input').value).to eq('foobar')
        #   expect(find_field('Email').value).to eq('user@example.com')
        #
        #   # good
        #   expect(page).to have_field(with: 'foobar')
        #   expect(page).to have_field('Email', with: 'user@example.com')
        #
        class FindElementValueEq < ::RuboCop::Cop::Base
          extend AutoCorrector

          MSG = 'Prefer `have_field` over checking `find(...).value`.'
          RESTRICT_ON_SEND = %i[expect].freeze
          FIELD_ELEMENT_SELECTORS = %w[input textarea].freeze

          # @!method find_element_value_eq(node)
          def_node_matcher :find_element_value_eq, <<~PATTERN
            (send
              (send nil? :expect (send $_ :value))
              ${:to :to_not :not_to}
              $(send nil? :eq $_)
            )
          PATTERN

          def on_send(node)
            find_element_value_eq(node.parent) do |finder, to_symbol,
                                                   matcher, expected|
              register_offense(node, finder, to_symbol, matcher, expected)
            end
          end
          alias on_csend on_send

          private

          def register_offense(node, finder, to_symbol, matcher, expected)
            replacement = replacement_for_finder(finder)
            return unless replacement

            expect_target, field_locator = replacement
            matcher_replacement =
              replacement_matcher(to_symbol, expected, field_locator)

            add_offense(node.loc.selector) do |corrector|
              autocorrect(corrector, node, matcher, expect_target,
                          matcher_replacement)
            end
          end

          def replacement_for_finder(node)
            return unless node&.send_type?

            case node.method_name
            when :find
              replacement_for_find(node)
            when :find_field
              replacement_for_find_field(node)
            end
          end

          def replacement_for_find(node)
            if (field_locator = field_selector_locator(node.arguments))
              return [expect_target(node), field_locator]
            end

            return unless field_element_selector?(node.arguments)

            [expect_target(node), nil]
          end

          def replacement_for_find_field(node)
            return unless node.arguments.one?

            [expect_target(node), node.first_argument]
          end

          def field_element_selector?(arguments)
            return field_element_name?(arguments.first) if arguments.one?

            arguments.length == 2 &&
              arguments.first.sym_type? &&
              arguments.first.value == :css &&
              field_element_name?(arguments.last)
          end

          def field_selector_locator(arguments)
            return unless arguments.length == 2

            selector_type, locator = arguments
            return unless field_selector?(selector_type)

            locator
          end

          def field_selector?(node)
            node.sym_type? && node.value == :field
          end

          def field_element_name?(node)
            node.str_type? && FIELD_ELEMENT_SELECTORS.include?(node.value)
          end

          def expect_target(node)
            node.receiver&.source || 'page'
          end

          def autocorrect(corrector, node, matcher, expect_target,
                          matcher_replacement)
            corrector.replace(node.first_argument, expect_target)
            corrector.replace(node.parent.loc.selector, 'to')
            corrector.replace(matcher, matcher_replacement)
          end

          def replacement_matcher(to_symbol, expected, field_locator)
            matcher = to_symbol == :to ? 'have_field' : 'have_no_field'
            args = ["with: #{replacement_value(expected)}"]
            args.unshift(replacement_value(field_locator)) if field_locator

            "#{matcher}(#{args.join(', ')})"
          end

          def replacement_value(expected)
            if method_call_with_no_parentheses?(expected)
              return "(#{expected.source})"
            end

            expected.source
          end

          def method_call_with_no_parentheses?(node)
            node.send_type? && node.arguments? && !node.parenthesized?
          end
        end
      end
    end
  end
end
