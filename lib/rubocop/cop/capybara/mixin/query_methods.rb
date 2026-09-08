# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Classification of Capybara's public query methods.
      # @api private
      module QueryMethods
        BUILT_IN_SELECTORS = %i[
          button checkbox css datalist_input datalist_option element field
          fieldset file_field fillable_field frame id label link link_or_button
          option radio_button select table table_row xpath
        ].freeze

        # Each entry contains the query type and its selector. `:selector`
        # means the selector is an argument; nil means it is not applicable.
        METHODS = begin
          methods = {
            find: %i[finder selector],
            ancestor: %i[finder selector],
            sibling: %i[finder selector],
            find_button: %i[finder button],
            find_by_id: %i[finder id],
            find_field: %i[finder field],
            find_link: %i[finder link]
          }
          %i[all find_all first].each do |name|
            methods[name] = %i[collection selector]
          end

          %w[
            ancestor button checked_field css element field link select
            selector sibling table unchecked_field xpath
          ].each do |selector|
            kind = case selector
                   when 'ancestor', 'sibling' then :selector
                   when 'checked_field', 'unchecked_field' then :field
                   else selector.to_sym
                   end
            prefixes = %w[assert assert_no refute has has_no have have_no]
            prefixes += %w[must_have wont_have] unless selector == 'element'
            prefixes.each do |prefix|
              name = "#{prefix}_#{selector}"
              name += '?' if prefix.start_with?('has')
              methods[name.to_sym] = [:selector, kind]
            end
          end

          %w[css selector xpath].each do |selector|
            %W[
              assert_matches_#{selector} assert_not_matches_#{selector}
              refute_matches_#{selector} matches_#{selector}?
              not_matches_#{selector}? match_#{selector} not_match_#{selector}
              must_match_#{selector} wont_match_#{selector}
            ].each { |name| methods[name.to_sym] = [:match, selector.to_sym] }
          end

          %w[text content].each do |kind|
            %W[
              assert_#{kind} assert_no_#{kind} refute_#{kind}
              has_#{kind}? has_no_#{kind}? have_#{kind} have_no_#{kind}
              must_have_#{kind} wont_have_#{kind}
            ].each { |name| methods[name.to_sym] = [:text, nil] }
          end

          %i[
            attach_file check choose click_button click_link
            click_link_or_button click_on fill_in select uncheck unselect
          ].each { |name| methods[name] = [:action, nil] }

          %w[assert have must_have].product(%w[all any none]) do |prefix, count|
            methods[:"#{prefix}_#{count}_of_selectors"] = %i[grouped selector]
          end

          methods.transform_values(&:freeze).freeze
        end
        private_constant :METHODS, :BUILT_IN_SELECTORS

        module_function

        # @param types [Array<Symbol>]
        # @return [Array<Symbol>]
        # @example
        #   names(:collection) # => [:all, :find_all, :first]
        def names(*types)
          METHODS.filter_map { |name, (type, _)| name if types.include?(type) }
        end

        # @param method_name [Symbol]
        # @return [Symbol, nil]
        # @example
        #   type(:find) # => :finder
        #   type(:unknown) # => nil
        def type(method_name)
          METHODS[method_name]&.first
        end

        # @param method_name [Symbol]
        # @return [Symbol, nil]
        # @example
        #   selector(:find_button) # => :button
        #   selector(:find) # => :selector
        #   selector(:have_text) # => nil
        def selector(method_name)
          METHODS[method_name]&.last
        end

        # @param selector [Symbol]
        # @return [Boolean]
        # @example
        #   built_in_selector?(:css) # => true
        #   built_in_selector?(:custom) # => false
        def built_in_selector?(selector)
          BUILT_IN_SELECTORS.include?(selector)
        end
      end
    end
  end
end
