# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for positive queries that succeed when there are no matches.
      #
      # @example
      #   # bad
      #   expect(page).to have_css('.item', minimum: 0)
      #   page.has_css?('.item', minimum: 0)
      #
      #   # good
      #   expect(page).to have_css('.item')
      #   expect(page).to have_css('.item', minimum: 0, maximum: 2)
      #   all('.item', minimum: 0)
      #
      class AlwaysTrueCountQuery < RuboCop::Cop::Base
        include CapybaraHelp

        MSG = '`minimum: 0` makes this positive query succeed with no matches.'
        OTHER_COUNT_OPTIONS = %i[count maximum between].freeze
        RESTRICT_ON_SEND = QueryMethods.names(:selector).select do |name|
          name = name.to_s
          name.start_with?('assert_', 'has_', 'have_', 'must_have_') &&
            !name.start_with?('assert_no_', 'has_no_', 'have_no_')
        end.freeze

        # @!method zero_minimum?(node)
        def_node_matcher :zero_minimum?, '(pair (sym :minimum) (int 0))'

        def on_send(node)
          return unless capybara_receiver?(node.receiver)
          return unless positive_usage?(node)

          minimum = always_true_minimum(node.last_argument)
          add_offense(minimum) if minimum
        end
        alias on_csend on_send

        private

        def positive_usage?(node)
          return true unless node.method_name.to_s.start_with?('have_')

          parent = node.parent
          parent&.send_type? && parent.method?(:to) &&
            parent.first_argument == node
        end

        def always_true_minimum(options)
          return unless known_options?(options)

          pairs = options.pairs
          return if pairs.any? { |pair| other_count_option?(pair) }

          minimum = pairs.select { |pair| pair.key.value == :minimum }
          minimum.first if minimum.one? && zero_minimum?(minimum.first)
        end

        def known_options?(options)
          return false unless options&.hash_type? && !options.braces?

          options.children.all? do |child|
            child.pair_type? && child.key.sym_type?
          end
        end

        def other_count_option?(pair)
          OTHER_COUNT_OPTIONS.include?(pair.key.value) && !pair.value.nil_type?
        end
      end
    end
  end
end
