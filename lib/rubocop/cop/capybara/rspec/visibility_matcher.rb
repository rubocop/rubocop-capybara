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
        # Set `DefaultSelector` to match `Capybara.default_selector` so
        # untyped `have_selector` calls can be corrected safely.
        # Read more at: https://www.rubydoc.info/gems/capybara/Capybara%2FNode%2FFinders:all
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

          RESTRICT_ON_SEND = CapybaraHelp::VISIBILITY_MATCHER_METHODS

          # @!method visible_true?(node)
          def_node_matcher :visible_true?, <<~PATTERN
            (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) true) ...>))
          PATTERN

          # @!method visible_false?(node)
          def_node_matcher :visible_false?, <<~PATTERN
            (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) false) ...>))
          PATTERN

          # @!method custom_filters?(node)
          def_node_matcher :custom_filters?, <<~PATTERN
            (hash <{(pair (sym :filter_set) _) (pair !sym _) kwsplat} ...>)
          PATTERN

          def on_send(node)
            false_msg = CapybaraHelp::VISIBILITY_FALSE_MESSAGE
            true_msg = CapybaraHelp::VISIBILITY_TRUE_MESSAGE
            visible_false?(node) { |arg| add_offense(arg, message: false_msg) }
            visible_true?(node) do |arg|
              add_offense(arg, message: true_msg) do |corrector|
                next unless autocorrectable?(node, arg)

                corrector.replace(arg.value, ':visible')
              end
            end
          end

          private

          def capybara_matcher?(method_name)
            RESTRICT_ON_SEND.include? method_name
          end

          def autocorrectable?(node, pair)
            options = pair.parent
            return false if options.braces? || custom_filters?(options)
            return true if QueryMethods.selector(node.method_name) != :selector

            selector = node.first_argument
            if selector&.sym_type?
              return QueryMethods.built_in_selector?(selector.value)
            end
            return false unless selector&.type?(:str, :dstr)

            default = cop_config.fetch('DefaultSelector', 'css').to_s.to_sym
            QueryMethods.built_in_selector?(default)
          end
        end
      end
    end
  end
end
