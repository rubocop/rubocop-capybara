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

        MSG_FALSE = 'Use `:all` or `:hidden` instead of `false`.'
        MSG_TRUE = 'Use `:visible` instead of `true`.'
        RESTRICT_ON_SEND = QueryMethods.names(
          :finder, :collection, :selector, :match, :action, :grouped
        ).freeze

        # @!method visibility_options(node)
        def_node_matcher :visibility_options, <<~PATTERN
          (call #capybara_receiver? _ <$(hash ...) ...>)
        PATTERN

        # @!method custom_filters?(node)
        def_node_matcher :custom_filters?, <<~PATTERN
          (hash <{(pair (sym :filter_set) _) (pair !sym _) kwsplat} ...>)
        PATTERN

        # @!method boolean_visibility?(node)
        def_node_matcher :boolean_visibility?, <<~PATTERN
          (pair (sym :visible) boolean)
        PATTERN

        def on_send(node)
          return unless (options = visibility_options(node))
          return if options.braces?
          return if custom_filters?(options) || custom_selector?(node)

          options.pairs.each do |pair|
            check_visibility(pair) if boolean_visibility?(pair)
          end
        end
        alias on_csend on_send

        private

        def custom_selector?(node)
          QueryMethods.selector(node.method_name) == :selector &&
            !QueryMethods.built_in_selector?(query_selector(node))
        end

        def query_selector(node)
          selector = node.first_argument
          return selector.value if selector&.sym_type?

          positional = node.arguments.reject do |arg|
            arg.type?(:hash, :block_pass)
          end
          return if positional.length > 1 && !selector.str_type?

          cop_config.fetch('DefaultSelector', 'css').to_s.to_sym
        end

        def check_visibility(pair)
          return add_offense(pair, message: MSG_FALSE) if pair.value.false_type?

          add_offense(pair, message: MSG_TRUE) do |corrector|
            corrector.replace(pair.value, ':visible')
          end
        end
      end
    end
  end
end
