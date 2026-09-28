# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Enforces use of `first` instead of `all` with `first` or `[0]`.
      #
      # @safety
      #   With default options, `all(...).first` and `all(...)[0]` return
      #   `nil` when no element matches, while `first(...)` raises an
      #   exception. Autocorrection can break code that depends on `nil`.
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
      class FindAllFirst < RuboCop::Cop::Base
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
          return if nil_sensitive_use?(parent)

          range = range_between(node.loc.selector.begin_pos,
                                parent.loc.selector.end_pos)
          selector = node.arguments.map(&:source).join(', ')
          add_offense(range,
                      message: format(MSG, selector: selector)) do |corrector|
            corrector.replace(range, "first(#{selector})")
          end
        end

        private

        def nil_sensitive_use?(node)
          return true if node.ancestors.any?(&:operator_keyword?)

          parent = node.parent
          (parent&.csend_type? && parent.receiver == node) ||
            (parent&.type?(:if, :while, :until) &&
             parent.condition == node)
        end
      end
    end
  end
end
