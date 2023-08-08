# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for click button or link style.
      #
      # @example EnforcedStyle: strict (default)
      #   # bad
      #   click_link_or_button('foo')
      #   click_on('foo')
      #
      #   # good
      #   click_link('foo')
      #   click_button('foo')
      #
      # @example EnforcedStyle: link_or_button
      #   # bad
      #   click_link('foo')
      #   click_button('foo')
      #
      #   # good
      #   click_link_or_button('foo')
      #   click_on('foo')
      #
      class ClickLinkOrButtonStyle < ::RuboCop::Cop::Base
        include ConfigurableEnforcedStyle

        MSG_STRICT =
          'Use `click_link` or `click_button` instead of `%<method>s`.'
        MSG_CLICK_LINK_OR_BUTTON =
          'Use `click_link_or_button` or `click_on` instead of `%<method>s`.'
        STRICT_METHODS = %i[click_link click_button].freeze
        CLICK_LINK_OR_BUTTON = %i[click_link_or_button click_on].freeze
        RESTRICT_ON_SEND = (STRICT_METHODS + CLICK_LINK_OR_BUTTON).freeze

        def on_send(node)
          return unless offense?(node)

          add_offense(node, message: offense_message(node))
        end

        private

        def offense?(node)
          style == :strict && !strict_method?(node) ||
            style == :link_or_button && !link_or_button_method?(node)
        end

        def offense_message(node)
          if style == :strict
            format(MSG_STRICT, method: node.method_name)
          elsif style == :link_or_button
            format(MSG_CLICK_LINK_OR_BUTTON, method: node.method_name)
          end
        end

        def strict_method?(node)
          STRICT_METHODS.include?(node.method_name)
        end

        def link_or_button_method?(node)
          CLICK_LINK_OR_BUTTON.include?(node.method_name)
        end
      end
    end
  end
end
