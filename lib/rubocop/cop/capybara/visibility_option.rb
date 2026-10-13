# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for boolean values passed to Capybara's `visible` option.
      #
      # `visible: false` finds both visible and hidden elements, rather than
      # only hidden elements. Use `:all`, `:hidden` or `:visible` instead.
      # Only `true` is autocorrected, to `:visible`.
      #
      # This cop targets Capybara's built-in selectors. Set `DefaultSelector`
      # to match `Capybara.default_selector`, or to `null` if it varies at
      # runtime. Queries using custom or unknown selectors are skipped.
      #
      # @example
      #   # bad
      #   find('.menu', visible: true)
      #   expect(page).to have_css('.menu', visible: false)
      #
      #   # good
      #   find('.menu', visible: :visible)
      #   find('.menu', visible: :all)
      #   find('.menu', visible: :hidden)
      #
      # @example DefaultSelector: custom
      #   # bad
      #   find(:css, '.menu', visible: true)
      #
      #   # good
      #   find('.menu', visible: true)
      #
      class VisibilityOption < RuboCop::Cop::Base
        extend AutoCorrector
        include CapybaraHelp
        include Visibility

        RESTRICT_ON_SEND = QueryMethods.names(
          :finder, :collection, :selector, :match, :action, :grouped
        ).difference(CapybaraHelp::VISIBILITY_MATCHER_METHODS).freeze

        # @!method visibility_options(node)
        def_node_matcher :visibility_options, <<~PATTERN
          (call #capybara_receiver? _ <$(hash ...) ...>)
        PATTERN

        # @!method boolean_visibility?(node)
        def_node_matcher :boolean_visibility?, <<~PATTERN
          (pair (sym :visible) boolean)
        PATTERN

        def on_send(node)
          return unless (options = visibility_options(node))
          return unless supported_visibility_query?(node, options)

          options.pairs.each do |pair|
            check_visibility(pair) if boolean_visibility?(pair)
          end
        end
        alias on_csend on_send
      end
    end
  end
end
