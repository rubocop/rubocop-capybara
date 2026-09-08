# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for query options that have no effect in Capybara.
      #
      # Count options passed to singular finders are not autocorrected because
      # removing them may conceal the author's intent.
      #
      # This cop targets Capybara's built-in selectors. Set `DefaultSelector`
      # to match `Capybara.default_selector`, or to `null` if it varies at
      # runtime. Queries using custom or unknown selectors are skipped.
      #
      # @example
      #   # bad
      #   find('.row', count: 3)
      #   find(:css, '.item', exact: true)
      #   find('.item', text: /foo/, exact_text: true)
      #   all(:css, '.item', match: :first)
      #   expect(page).to have_css('.item', count: 3, minimum: 1)
      #
      #   # good
      #   all('.row', count: 3)
      #   find(:css, '.item')
      #   find('.item', text: /foo/)
      #   all(:css, '.item')
      #   expect(page).to have_css('.item', count: 3)
      #
      # @example DefaultSelector: custom
      #   # bad
      #   find(:css, '.item', text: /foo/, exact_text: true)
      #
      #   # good
      #   find('.item', text: /foo/, exact_text: true)
      #
      class IneffectiveQueryOption < RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector
        include RangeHelp
        include CapybaraHelp

        RESTRICT_ON_SEND = QueryMethods.names(
          :finder, :collection, :selector, :match, :text
        ).freeze
        COUNT_OPTIONS = %i[count minimum maximum between].freeze
        MATCH_STRATEGIES = %i[first smart prefer_exact one].freeze

        FIND_COUNT_MSG =
          '`%<option>s` has no effect when passed to `%<method>s`.'
        EXACT_MSG = '`exact` has no effect on CSS queries.'
        EXACT_TEXT_MSG =
          '`exact_text` has no effect when `text` is a regexp.'
        MATCH_MSG =
          '`match` has no effect when passed to `%<method>s`.'
        SHADOWED_COUNT_MSG =
          '`%<option>s` has no effect when `count` is specified.'

        # @!method query_options(node)
        def_node_matcher :query_options, <<~PATTERN
          (call #capybara_receiver? _ <$(hash ...) ...>)
        PATTERN

        # @!method custom_filters?(node)
        def_node_matcher :custom_filters?, <<~PATTERN
          (hash <{(pair (sym {:filter_set :session_options}) _) (pair !sym _) kwsplat} ...>)
        PATTERN

        # @!method removable_value?(node)
        def_node_matcher :removable_value?, <<~PATTERN
          {basic_literal? (range {int nil?} {int nil?})}
        PATTERN

        def on_send(node)
          return unless (options = query_options(node))
          return if options.braces?
          return if custom_filters?(options)

          issues = options.pairs.filter_map do |pair|
            issue_for(node, options, pair)
          end
          return if issues.empty?

          register_issues(node, options, issues)
        end
        alias on_csend on_send

        private

        def register_issues(node, options, issues)
          correction_pair = issues.find do |pair, _, correctable|
            correctable && removable?(options, pair) && !comments_in?(node)
          end
          issues.each do |pair, message, _|
            add_offense(pair, message: message) do |corrector|
              next unless pair == correction_pair&.first

              remove_option(corrector, node, options, pair)
            end
          end
        end

        def issue_for(node, options, pair)
          option = pair.key.value
          issue = find_count_issue(node, option) ||
            exact_issue(node, option) ||
            exact_text_issue(node, option, pair, options) ||
            match_issue(node, option, pair) ||
            shadowed_count_issue(node, option, options)

          [pair, *issue] if issue
        end

        def find_count_issue(node, option)
          return unless QueryMethods.type(node.method_name) == :finder
          return unless COUNT_OPTIONS.include?(option)
          return if custom_selector?(node)

          [
            format(FIND_COUNT_MSG,
                   option: option,
                   method: node.method_name),
            false
          ]
        end

        def shadowed_count_issue(node, option, options)
          return if QueryMethods.type(node.method_name) == :match
          return unless count_query_with_known_selector?(node)
          return unless shadowed_count?(option, options)

          [format(SHADOWED_COUNT_MSG, option: option), true]
        end

        def exact_issue(node, option)
          [EXACT_MSG, true] if option == :exact && css_query?(node)
        end

        def exact_text_issue(node, option, pair, options)
          return unless option == :exact_text
          return unless ineffective_exact_text?(node, pair, options)

          [EXACT_TEXT_MSG, true]
        end

        def match_issue(node, option, pair)
          return unless option == :match && ineffective_match?(node, pair)

          [format(MATCH_MSG, method: node.method_name), true]
        end

        def css_query?(node)
          selector = QueryMethods.selector(node.method_name)
          selector == :css ||
            (selector == :selector && explicit_selector(node) == :css)
        end

        def explicit_selector(node)
          argument = node.first_argument
          argument.value if argument&.sym_type?
        end

        def ineffective_exact_text?(node, pair, options)
          exact_text_supported_call?(node) &&
            effective_option_pair(options, :exact_text) == pair &&
            pair.value.type?(:boolean) &&
            effective_option_pair(options, :text)&.value&.regexp_type?
        end

        def exact_text_supported_call?(node)
          QueryMethods.type(node.method_name) != :text &&
            !custom_selector?(node)
        end

        def ineffective_match?(node, pair)
          QueryMethods.type(node.method_name) == :collection &&
            QueryMethods.built_in_selector?(explicit_selector(node)) &&
            pair.value.sym_type? &&
            MATCH_STRATEGIES.include?(pair.value.value)
        end

        def shadowed_count?(option, options)
          option != :count && COUNT_OPTIONS.include?(option) &&
            count_specified?(options)
        end

        def count_query_with_known_selector?(node)
          selector = QueryMethods.selector(node.method_name)
          return true unless selector == :selector

          QueryMethods.built_in_selector?(explicit_selector(node))
        end

        def custom_selector?(node)
          QueryMethods.selector(node.method_name) == :selector &&
            !QueryMethods.built_in_selector?(query_selector(node))
        end

        def query_selector(node)
          selector = explicit_selector(node)
          return selector if selector

          positional = node.arguments.reject do |arg|
            arg.type?(:hash, :block_pass)
          end
          return if positional.length > 1

          cop_config.fetch('DefaultSelector', 'css').to_s.to_sym
        end

        def count_specified?(options)
          effective_option_pair(options, :count)&.value&.truthy_literal?
        end

        def effective_option_pair(options, name)
          options.pairs.reverse_each.find { |pair| pair.key.value == name }
        end

        def comments_in?(node)
          processed_source.comments.any? do |comment|
            comment.loc.line.between?(node.first_line, node.last_line)
          end
        end

        def removable?(options, pair)
          return false unless removable_value?(pair.value)
          return false if pair.value.str_type? && pair.value.heredoc?

          options.pairs.one? { |other| other.key == pair.key }
        end

        def remove_option(corrector, node, options, pair)
          first = node.first_argument == options &&
            options.children.first == pair
          side = first ? :right : :left
          range = range_with_surrounding_space(pair.source_range, side: side)
          range = range_with_surrounding_comma(range, side)
          corrector.remove(range_with_surrounding_space(range, side: side))
        end
      end
    end
  end
end
