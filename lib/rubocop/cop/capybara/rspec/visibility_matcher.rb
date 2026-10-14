# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # Checks for boolean visibility in Capybara RSpec matchers.
        #
        # Capybara lets you find elements that match a certain visibility using
        # the `:visible` option. `:visible` accepts both boolean and symbols as
        # values, however using booleans can have unwanted effects. `visible:
        # false` does not find just invisible elements, but both visible and
        # invisible elements. For expressiveness and clarity, use one of the
        # symbol values, `:all`, `:hidden` or `:visible`.
        # Only `true` is autocorrected, to `:visible`.
        # Set `DefaultSelector` to match `Capybara.default_selector`, or to
        # `null` if it varies at runtime.
        # Read more at: https://www.rubydoc.info/gems/capybara/Capybara%2FNode%2FFinders:all
        #
        # @safety
        #   This cop's autocorrection is unsafe because custom filters on
        #   built-in selectors may treat `true` and `:visible` differently.
        #
        # @example
        #   # bad
        #   expect(page).to have_selector('.foo', visible: true)
        #   expect(page).to have_css('.foo', visible: false)
        #   expect(page).to have_link('my link', visible: false)
        #
        #   # good
        #   expect(page).to have_selector('.foo', visible: :visible)
        #   expect(page).to have_css('.foo', visible: :all)
        #   expect(page).to have_link('my link', visible: :hidden)
        #
        class VisibilityMatcher < RuboCop::Cop::Base
          extend AutoCorrector
          include Visibility

          RESTRICT_ON_SEND = CapybaraHelp::VISIBILITY_MATCHER_METHODS

          # @!method visible_true?(node)
          def_node_matcher :visible_true?, <<~PATTERN
            (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) true) ...>))
          PATTERN

          # @!method visible_false?(node)
          def_node_matcher :visible_false?, <<~PATTERN
            (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) false) ...>))
          PATTERN

          def on_send(node)
            visible_false?(node) { |arg| check_visibility(arg) }
            visible_true?(node) do |arg|
              check_visibility(arg) { autocorrectable?(node, arg) }
            end
          end

          private

          def capybara_matcher?(method_name)
            RESTRICT_ON_SEND.include? method_name
          end

          def autocorrectable?(node, pair)
            if QueryMethods.selector(node.method_name) == :selector
              selector = node.first_argument
              # An unknown argument may be a custom selector name.
              return false unless selector.type?(:hash, :sym, :str, :dstr)
            end

            supported_visibility_query?(node, pair.parent)
          end
        end
      end
    end
  end
end
