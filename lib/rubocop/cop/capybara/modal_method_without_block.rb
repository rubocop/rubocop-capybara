# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks that modal handling methods are called with a block.
      #
      # @example
      #   # bad
      #   accept_confirm
      #   page.accept_prompt(with: 'answer')
      #
      #   # good
      #   accept_confirm { click_button 'Delete' }
      #   page.accept_prompt(with: 'answer', &trigger_modal)
      #
      class ModalMethodWithoutBlock < RuboCop::Cop::Base
        MSG = 'Call `%<method>s` with a block.'
        RESTRICT_ON_SEND = %i[
          accept_alert
          accept_confirm
          accept_prompt
          dismiss_confirm
          dismiss_prompt
        ].freeze

        def on_send(node)
          return if node.block_literal? || node.block_argument?
          return if node.last_argument&.forwarded_args_type?

          add_offense(node, message: format(MSG, method: node.method_name))
        end
        alias on_csend on_send
      end
    end
  end
end
