# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Enforces use of `first` instead of `all` with `first` or `[0]`.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `all` returns a
      #   `Capybara::Result` (an enumerable collection), while `first`
      #   returns a single `Capybara::Node::Element`. Replacing `all`
      #   with `first` may break code that depends on the return value
      #   being a collection (e.g. calling `.each` on the result).
      #
      # @example
      #
      #   # bad
      #   all('a').first
      #   all('a')[0]
      #
      #   # good
      #   first('a')
      #
      class FindAllFirst < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `first(%<selector>s)`.'
        RESTRICT_ON_SEND = %i[all].freeze

        # @!method find_all_first?(node)
        def_node_matcher :find_all_first?, <<~PATTERN
          {
            (send (send _ :all _ ...) :first)
            (send (send _ :all _ ...) :[] (int 0))
          }
        PATTERN

        def on_send(node)
          return unless (parent = node.parent)
          return unless find_all_first?(parent)
          return if part_of_logical_operator?(parent)

          range = range_between(node.loc.selector.begin_pos,
                                parent.loc.selector.end_pos)
          selector = node.arguments.map(&:source).join(', ')
          add_offense(range,
                      message: format(MSG, selector: selector)) do |corrector|
            corrector.replace(range, "first(#{selector})")
          end
        end

        private

        def part_of_logical_operator?(node)
          node.ancestors.any?(&:operator_keyword?)
        end
      end
    end
  end
end
