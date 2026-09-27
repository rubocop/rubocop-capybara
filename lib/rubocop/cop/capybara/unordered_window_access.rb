# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks positional access to Capybara windows, whose order is undefined.
      #
      # @example
      #   # bad
      #   popup = windows.last
      #   original = page.windows.first
      #
      #   # good
      #   popup = window_opened_by { click_link 'Open' }
      #   original = current_window
      #
      class UnorderedWindowAccess < RuboCop::Cop::Base
        MSG = 'Selecting a window by position relies on undefined order. ' \
              'Use `window_opened_by` or `current_window`.'
        RESTRICT_ON_SEND = %i[first last [] at fetch].freeze

        # @!method capybara_windows?(node)
        def_node_matcher :capybara_windows?, <<~PATTERN
          (call
            {nil? self
             (call {nil? self} :page)
             (call (const {nil? cbase} :Capybara) :current_session)}
            :windows)
        PATTERN

        def on_send(node)
          return if node.method?(:[]) && node.first_argument&.type?(:range)

          add_offense(node) if capybara_windows?(node.receiver)
        end
        alias on_csend on_send
      end
    end
  end
end
