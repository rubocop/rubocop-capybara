# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Css selector parser.
      # @api private
      class CssAttributesParser
        QUOTE_CHARS = ['"', "'"].freeze

        def initialize(selector)
          @selector = selector
          @state = :initial
          @temp = ''
          @results = {}
          @bracket_count = 0
        end

        # @return [Hash<String, String, Boolean, nil>]
        def parse # rubocop:disable Metrics/MethodLength
          @selector.each_char do |char|
            if char == '['
              on_bracket_start
            elsif char == ']'
              on_bracket_end
            elsif @state == :inside_attr
              @temp += char
            end
          end
          @results
        end

        private

        def on_bracket_start
          @bracket_count += 1
          if @state == :initial
            @state = :inside_attr
          else
            @temp += '['
          end
        end

        def on_bracket_end
          @bracket_count -= 1
          if @bracket_count.zero?
            @state = :initial
            key, value = @temp.split('=', 2)
            @results[key] = normalize_value(value)
            @temp.clear
          else
            @temp += ']'
          end
        end

        # @param value [String]
        # @return [Boolean, String, nil]
        # @example
        #   normalize_value('true') # => true
        #   normalize_value('false') # => false
        #   normalize_value(nil) # => nil
        #   normalize_value("foo") # => "foo"
        #   normalize_value("'foo'") # => "foo"
        def normalize_value(value)
          case value
          when 'true' then true
          when 'false' then false
          when nil then nil
          else strip_outer_quotes(value)
          end
        end

        def strip_outer_quotes(value)
          return value unless quoted?(value)

          value[1...-1]
        end

        def quoted?(value)
          return false if value.length < 2

          quote = value[0]
          QUOTE_CHARS.include?(quote) && value.end_with?(quote)
        end
      end
    end
  end
end
