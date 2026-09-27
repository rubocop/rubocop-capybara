# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Checks for absolute XPath searches on Capybara elements.
      #
      # An XPath starting with `//` searches from the document root, even when
      # the query is called on an element. Use `.//` to stay within it.
      # Direct RSpec `let` and named `subject` element definitions are
      # recognized.
      #
      # @example
      #   # bad
      #   page.find('.dialog').find(:xpath, '//button')
      #   dialog = page.find('.dialog')
      #   dialog.find(:xpath, '//button')
      #   RSpec.describe 'dialog' do
      #     let(:dialog) { find('.dialog') }
      #     it { dialog.find(:xpath, '//button') }
      #   end
      #
      #   # good
      #   page.find('.dialog').find(:xpath, './/button')
      #   page.find(:xpath, '//button')
      #
      class AbsoluteXPathInElementScope < RuboCop::Cop::Base
        include CapybaraHelp

        MSG = 'Use `.//` for an XPath search within an element.'
        RESTRICT_ON_SEND = %i[find all find_all first].freeze
        RSPEC_GROUPS = %i[
          describe context feature shared_examples shared_context
        ].freeze
        RSPEC_HELPERS = %i[let let! subject].freeze

        # @!method xpath_literal(node)
        def_node_matcher :xpath_literal, '(call _ _ (sym :xpath) $(str _) ...)'

        # @!method element_finder?(node)
        def_node_matcher :element_finder?, <<~PATTERN
          (call #capybara_receiver? :find ...)
        PATTERN

        def on_send(node)
          xpath = xpath_literal(node)
          return unless xpath&.value&.start_with?('//')
          return unless element_receiver?(node.receiver)

          add_offense(xpath)
        end
        alias on_csend on_send

        private

        def element_receiver?(node)
          return true if node&.call_type? && element_finder?(node)
          return element_finder?(local_variable_value(node)) if node&.lvar_type?

          element_finder?(rspec_helper_value(node)) if node&.call_type?
        end

        def rspec_helper_value(node)
          return unless node.receiver.nil? && node.arguments.empty?

          node.each_ancestor(:block).each do |group|
            next unless rspec_group?(group)

            definition = named_helper(group, node.method_name)
            return definition.body if definition
          end
          nil
        end

        def rspec_group?(block)
          call = block.send_node
          return false unless RSPEC_GROUPS.include?(call.method_name)

          call.receiver.nil? || (call.receiver.const_type? &&
            call.receiver.const_name == 'RSpec')
        end

        def named_helper(group, name)
          body = group.body
          statements = body.begin_type? ? body.children : [body]
          statements.reverse_each.find do |statement|
            named_rspec_helper?(statement, name)
          end
        end

        def named_rspec_helper?(statement, name)
          return false unless statement.block_type?

          call = statement.send_node
          return false if call.receiver
          return false unless RSPEC_HELPERS.include?(call.method_name)

          argument = call.first_argument
          argument&.sym_type? && argument.value == name
        end
      end
    end
  end
end
