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
      #   find('a', match: :first)
      #   all('a', match: :first)
      #
      #   # good
      #   first('a')
      #
      class FindAllFirst < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `first(%<selector>s)`.'
        RESTRICT_ON_SEND = %i[all find].freeze

        # Global query options accepted by Capybara's `all`/`first`. A
        # keyword-only `all(...)` whose keys are all valid Capybara options
        # (e.g. `all(text: 'Home')`) is a real Capybara call. One with an
        # unknown key (e.g. `all(include_inactive: true)`) is a non-Capybara
        # collection method whose autocorrect to `first(...)` would break.
        CAPYBARA_FINDER_OPTIONS = Set.new(
          %i[
            above below left_of right_of near
            count minimum maximum between
            text exact_text normalize_ws
            visible obscured exact match wait
            id class style focused
          ]
        ).freeze

        # @!method find_all_first?(node)
        def_node_matcher :find_all_first?, <<~PATTERN
          {
            (send (send _ :all _ ...) :first)
            (send (send _ :all _ ...) :[] (int 0))
          }
        PATTERN

        # @!method include_match_first?(node)
        def_node_matcher :include_match_first?, <<~PATTERN
          (send _ {:find :all} _ $(hash <(pair (sym :match) (sym :first)) ...>))
        PATTERN

        def on_send(node)
          on_all_first(node)
          on_match_first(node)
        end

        private

        def on_all_first(node)
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

        def on_match_first(node)
          include_match_first?(node) do |hash|
            selector = ([node.first_argument.source] + replaced_hash(hash))
              .join(', ')
            range = range_between(node.loc.selector.begin_pos,
                                  node.source_range.end_pos)
            add_offense(range,
                        message: format(MSG, selector: selector)) do |corrector|
              corrector.replace(range, "first(#{selector})")
            end
          end
        end

        def replaced_hash(hash)
          hash.child_nodes.flat_map(&:source).reject do |arg|
            arg == 'match: :first'
          end
        end

        def part_of_logical_operator?(node)
          node.ancestors.any?(&:operator_keyword?)
        end

        # Skips keyword-only `all(...)` calls that are not Capybara finders.
        # Capybara's `all` takes a positional selector, but also accepts a
        # selectorless keyword-only form (e.g. `all(text: 'Home')`). Those are
        # still valid Capybara calls, so only skip when a keyword is not a
        # known Capybara option (or the keys can't be determined, e.g. a double
        # splat). `find_all_first?` guarantees `node` is an `all` send with an
        # argument.
        def keyword_only_all?(node)
          first_argument = node.first_argument
          return false unless first_argument.hash_type?

          !capybara_finder_options_only?(first_argument)
        end

        def capybara_finder_options_only?(hash_node)
          hash_node.pairs.size == hash_node.children.size &&
            hash_node.pairs.all? do |pair|
              pair.key.sym_type? &&
                CAPYBARA_FINDER_OPTIONS.include?(pair.key.value)
            end
        end
      end
    end
  end
end
