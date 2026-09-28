# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for redundant `within find(...)` calls.
      #
      # @example
      #   # bad
      #   within find('foo.bar') do
      #     # ...
      #   end
      #
      #   # good
      #   within 'foo.bar' do
      #     # ...
      #   end
      #
      #   # bad
      #   within find_by_id('foo') do
      #     # ...
      #   end
      #
      #   # good
      #   within :id, 'foo' do
      #     # ...
      #   end
      #
      class RedundantWithinFind < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Redundant `within %<method>s(...)` call detected.'
        RESTRICT_ON_SEND = %i[within].freeze
        FIND_METHODS = Set.new(%i[find find_by_id]).freeze

        # @!method within_find(node)
        def_node_matcher :within_find, <<~PATTERN
          (send nil? :within
            $(send nil? %FIND_METHODS ...))
        PATTERN

        def on_send(node)
          within_find(node) do |find_node|
            replacement = replaced(find_node)

            add_offense(find_node, message: msg(find_node)) do |corrector|
              corrector.replace(find_node, replacement) if replacement
            end
          end
        end

        private

        def msg(node)
          format(MSG, method: node.method_name)
        end

        def replaced(node)
          return unless node.first_argument
          return if node.arguments.any?(&:block_pass_type?)

          args = node.arguments.map(&:source).join(', ')
          node.method?(:find_by_id) ? ":id, #{args}" : args
        end
      end
    end
  end
end
