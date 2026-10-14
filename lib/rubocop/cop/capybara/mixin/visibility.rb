# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Shared visibility query checks and offense handling.
      # @api private
      module Visibility
        extend RuboCop::AST::NodePattern::Macros

        # @!method custom_filters?(node)
        def_node_matcher :custom_filters?, <<~PATTERN
          (hash <{(pair (sym :filter_set) _) (pair !sym _) kwsplat} ...>)
        PATTERN

        private

        def supported_visibility_query?(node, options)
          return false if options.braces? || custom_filters?(options)
          return true if QueryMethods.selector(node.method_name) != :selector

          QueryMethods.built_in_selector?(query_selector(node))
        end

        def query_selector(node)
          selector = node.first_argument
          return selector.value if selector&.sym_type?

          positional = node.arguments.reject do |arg|
            arg.type?(:hash, :block_pass)
          end
          return if positional.length > 1 && !selector.str_type?

          cop_config['DefaultSelector'].to_s.to_sym
        end

        def check_visibility(pair)
          if pair.value.false_type?
            return add_offense(pair, message: CapybaraHelp::VISIBILITY_FALSE_MESSAGE)
          end

          add_offense(
            pair, message: CapybaraHelp::VISIBILITY_TRUE_MESSAGE
          ) do |corrector|
            next if block_given? && !yield

            corrector.replace(pair.value, ':visible')
          end
        end
      end
    end
  end
end
