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
      # Capybara's selectorless keyword-only form (e.g. `all(text: 'Home')`)
      # is only flagged when every keyword is a valid Capybara option, to
      # avoid breaking non-Capybara `all` methods. Set `DefaultSelector` to
      # match `Capybara.default_selector` so that its filters are accepted.
      #
      # @example DefaultSelector: css (default)
      #   # bad
      #   all(text: 'Home').first
      #
      #   # good
      #   first(text: 'Home')
      #   jobs.all(include_inactive: true).first
      #
      # @example DefaultSelector: field
      #   # bad
      #   all(disabled: true).first
      #
      #   # good
      #   first(disabled: true)
      #
      class FindAllFirst < RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `first(%<selector>s)`.'
        RESTRICT_ON_SEND = %i[all].freeze

        # `SelectorQuery::VALID_KEYS`, `SelectorQuery#initialize` keywords, and
        # `all`'s `allow_reload`. Capybara raises on any other key unless the
        # selector defines it as a filter.
        CAPYBARA_FINDER_OPTIONS = Set.new(
          %i[
            above below left_of right_of near
            count minimum maximum between
            text exact_text normalize_ws
            visible obscured exact match wait
            id class style focused filter_set
            enable_aria_label enable_aria_role test_id
            selector_format order session_options allow_reload
          ]
        ).freeze

        FILTERLESS_SELECTORS = %i[css xpath].freeze

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
          return if keyword_only_all?(node)

          register_all_first_offense(node, parent)
        end

        def register_all_first_offense(node, parent)
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

        # Selectorless `all(text: 'Home')` is valid Capybara, so only skip
        # keyword-only calls whose keys can't all be Capybara options.
        def keyword_only_all?(node)
          first_argument = node.first_argument
          return false unless first_argument.hash_type?
          return false unless filterless_default_selector?

          !capybara_finder_options_only?(first_argument)
        end

        # Other default selectors (e.g. `:field`) define their own filters.
        def filterless_default_selector?
          FILTERLESS_SELECTORS.include?(
            cop_config.fetch('DefaultSelector', 'css').to_s.to_sym
          )
        end

        def capybara_finder_options_only?(hash_node)
          return false unless (keys = symbol_keys(hash_node))

          # `filter_set:` makes that filter set's filters valid options.
          keys.include?(:filter_set) ||
            keys.all? { |key| CAPYBARA_FINDER_OPTIONS.include?(key) }
        end

        def symbol_keys(hash_node)
          return unless hash_node.pairs.size == hash_node.children.size
          return unless hash_node.keys.all?(&:sym_type?)

          hash_node.keys.map(&:value)
        end
      end
    end
  end
end
