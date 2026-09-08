# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Enforces use of `Element#[]` instead of `native.attribute`.
      #
      # Only calls on Capybara finder chains are checked.
      #
      # @safety
      #   This cop's autocorrection is unsafe because attribute values may
      #   differ between the driver API and Capybara's `Element#[]`.
      #
      # @example
      #   # bad
      #   find('.item').native.attribute(:id)
      #   page.find('.item').native.attribute('aria-label')
      #
      #   # good
      #   find('.item')[:id]
      #   page.find('.item')['aria-label']
      #
      class NativeAttribute < RuboCop::Cop::Base
        extend AutoCorrector
        include CapybaraHelp

        MSG = 'Use `Element#[]` instead of driver-specific `native.attribute`.'
        RESTRICT_ON_SEND = %i[attribute].freeze

        # @!method native_attribute(node)
        def_node_matcher :native_attribute, <<~PATTERN
          (call
            $(call #element_finder? :native)
            :attribute
            $({str sym} _))
        PATTERN

        # @!method element_finder?(node)
        def_node_matcher :element_finder?, <<~PATTERN
          {(call #capybara_receiver?
             {:ancestor :find :find_button :find_by_id
              :find_field :find_link :first :sibling} ...)
           (any_block #element_finder? ...)
           (begin #element_finder?)}
        PATTERN

        def on_send(node)
          native_attribute(node) do |native, attribute|
            add_offense(node) do |corrector|
              next if attribute.str_type? && attribute.heredoc?

              correct_attribute(corrector, node, native, attribute)
            end
          end
        end
        alias on_csend on_send

        private

        def correct_attribute(corrector, node, native, attribute)
          range = node.source_range.with(begin_pos: native.loc.dot.begin_pos)
          return if processed_source.comments.any? do |comment|
            range.contains?(comment.source_range)
          end

          safe_navigation = native.csend_type? && node.csend_type?
          template = safe_navigation ? '&.[](%s)' : '[%s]'
          corrector.replace(range, format(template, attribute.source))
        end
      end
    end
  end
end
