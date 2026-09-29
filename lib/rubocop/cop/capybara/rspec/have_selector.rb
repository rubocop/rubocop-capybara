# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      module RSpec
        # Use CSS or XPath matchers instead of generic selector matchers.
        #
        # @example
        #   # bad
        #   expect(foo).to have_selector(:css, 'bar')
        #   expect(foo).to have_no_selector(:css, 'bar')
        #
        #   # good
        #   expect(foo).to have_css('bar')
        #   expect(foo).to have_no_css('bar')
        #
        #   # bad
        #   expect(foo).to have_selector(:xpath, 'bar')
        #   expect(foo).to have_no_selector(:xpath, 'bar')
        #
        #   # good
        #   expect(foo).to have_xpath('bar')
        #   expect(foo).to have_no_xpath('bar')
        #
        # @example DefaultSelector: css (default)
        #   # bad
        #   expect(foo).to have_selector('bar')
        #
        #   # good
        #   expect(foo).to have_css('bar')
        #
        # @example DefaultSelector: xpath
        #   # bad
        #   expect(foo).to have_selector('bar')
        #
        #   # good
        #   expect(foo).to have_xpath('bar')
        #
        class HaveSelector < RuboCop::Cop::Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'Use `%<good>s` instead of `%<bad>s`.'
          RESTRICT_ON_SEND = %i[have_selector have_no_selector].freeze
          SELECTORS = %i[css xpath].freeze

          def on_send(node)
            return unless (argument = node.first_argument)

            on_select_with_type(node, argument) if argument.sym_type?
            on_select_without_type(node) if %i[str dstr].include?(argument.type)
          end

          private

          def on_select_with_type(node, type)
            return unless SELECTORS.include?(type.value)
            return unless (locator = node.arguments[1])

            replacement = replacement(node, type.value)
            add_offense(node,
                        message: message(node, replacement)) do |corrector|
              corrector.remove(deletion_range(type, locator))
              corrector.replace(node.loc.selector, replacement)
            end
          end

          def deletion_range(first_argument, second_argument)
            range_between(first_argument.source_range.begin_pos,
                          second_argument.source_range.begin_pos)
          end

          def on_select_without_type(node)
            return unless (selector = default_selector)

            replacement = replacement(node, selector)
            add_offense(node,
                        message: message(node, replacement)) do |corrector|
              corrector.replace(node.loc.selector, replacement)
            end
          end

          def replacement(node, selector)
            node.method_name.to_s.sub('selector', selector.to_s)
          end

          def message(node, replacement)
            format(MSG, good: replacement, bad: node.method_name)
          end

          def default_selector
            selector = cop_config['DefaultSelector'].to_s.to_sym
            selector if SELECTORS.include?(selector)
          end
        end
      end
    end
  end
end
