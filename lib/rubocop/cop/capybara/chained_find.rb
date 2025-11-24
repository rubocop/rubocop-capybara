# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Avoid chaining `find` methods and combine selectors.
      #
      # Combining selectors into a single `find` call is more efficient than
      # chaining multiple `find` calls, as it reduces the number of DOM queries.
      #
      # @example
      #   # bad
      #   page.find('#foo').find('.bar')
      #   page.find('#foo').find('.bar').find('.baz')
      #
      #   # good
      #   page.find('#foo .bar')
      #   page.find('#foo .bar .baz')
      #
      class ChainedFind < ::RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Avoid chaining `find` methods. ' \
              'Combine the selectors into a single `find` call.'
        MSG_WITH_COMBINED = 'Use `find(\'%<combined>s\')` instead of ' \
                            'chaining `find` methods.'
        RESTRICT_ON_SEND = %i[find].freeze

        # @!method single_string_find?(node)
        def_node_matcher :single_string_find?, <<~PATTERN
          (send _ :find (str $_))
        PATTERN

        def on_send(node)
          return unless chained_find?(node)

          find_receiver = find_receiver(node.receiver)
          return unless find_receiver

          register_offense(node, find_receiver)
        end
        alias on_csend on_send

        private

        def chained_find?(node)
          node.method?(:find) && node.receiver
        end

        def find_receiver(receiver)
          return unwrapped_receiver(receiver) if receiver.block_type?

          receiver if receiver.send_type? && receiver.method?(:find)
        end

        def unwrapped_receiver(block_node)
          send_node = block_node.send_node
          send_node if send_node.method?(:find)
        end

        def register_offense(node, find_receiver)
          if safe_to_autocorrect?(node, find_receiver)
            add_correctable_offense(node, find_receiver)
          else
            add_offense(node)
          end
        end

        def add_correctable_offense(node, find_receiver)
          combined = combined_selector(node, find_receiver)
          message = format(MSG_WITH_COMBINED, combined: combined)

          if nested_in_chained_find?(node)
            add_offense(node, message: message)
          else
            add_offense(node, message: message) do |corrector|
              corrector.replace(node, replacement(node, combined))
            end
          end
        end

        def nested_in_chained_find?(node)
          node.parent&.send_type? &&
            node.parent.method?(:find) &&
            node.parent.receiver == node
        end

        def safe_to_autocorrect?(node, receiver)
          single_string_argument?(node) && single_string_argument?(receiver)
        end

        def single_string_argument?(node)
          node.arguments.one? &&
            !node.block_node &&
            single_string_find?(node)
        end

        def combined_selector(node, receiver)
          selectors = collect_selectors(receiver)
          current = node.first_argument.value

          "#{selectors} #{current}"
        end

        def collect_selectors(node)
          [].tap do |selectors|
            current = node
            while (selector = single_string_find?(current))
              selectors.unshift(selector)
              current = current.receiver
              break unless current&.send_type? && current.method?(:find)
            end
          end.join(' ')
        end

        def replacement(node, combined_selector)
          root = chain_root(node)
          receiver_source = root.receiver&.source

          [receiver_source, "find('#{combined_selector}')"].compact.join('.')
        end

        def chain_root(node)
          root = node
          while root.receiver&.send_type? && root.receiver.method?(:find)
            root = root.receiver
          end
          root
        end
      end
    end
  end
end
