# frozen_string_literal: true

require 'strscan'

module RuboCop
  module Cop
    module Capybara
      # Helps parsing css selector.
      # @api private
      module CssSelector
        module_function

        # @param selector [String]
        # @return [String]
        # @example
        #   id('#some-id') # => some-id
        #   id('.some-cls') # => nil
        #   id('#some-id.cls') # => some-id
        def id(selector)
          return unless id?(selector)

          selector.delete('#').gsub(selector.scan(/[^\\]([>,+~.].*)/).join, '')
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   id?('#some-id') # => true
        #   id?('.some-cls') # => false
        def id?(selector)
          selector.start_with?('#')
        end

        # @param selector [String]
        # @return [Array<String>]
        # @example
        #   classes('#some-id') # => []
        #   classes('.some-cls') # => ['some-cls']
        #   classes('#some-id.some-cls') # => ['some-cls']
        #   classes('#some-id.cls1.cls2') # => ['cls1', 'cls2']
        def classes(selector)
          selector.scan(/\.([\w-]*)/).flatten
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   attribute?('[attribute]') # => true
        #   attribute?('attribute') # => false
        def attribute?(selector)
          selector.start_with?('[')
        end

        # @param selector [String]
        # @return [Array<String>]
        # @example
        #   attributes('a[foo-bar_baz]') # => {"foo-bar_baz=>nil}
        #   attributes('button[foo][bar=baz]') # => {"foo"=>nil, "bar"=>"'baz'"}
        #   attributes('table[foo=bar]') # => {"foo"=>"'bar'"}
        #   attributes('[foo="bar[baz][qux]"]') # => {"foo"=>"'bar[baz][qux]'"}
        def attributes(selector)
          CssAttributesParser.new(selector).parse
        end

        # @param selector [String]
        # @return [Array<String>]
        # @example
        #   pseudo_classes('button:not([disabled])') # => ['not()']
        #   pseudo_classes('a:enabled:not([valid])') # => ['enabled', 'not()']
        def pseudo_classes(selector)
          # Attributes must be excluded or else the colon in the `href`s URL
          # will also be picked up as pseudo classes.
          # "a:not([href='http://example.com']):enabled" => "a:not():enabled"
          ignored_attribute = selector.gsub(/\[.*?\]/, '')
          # "a:not():enabled" => ["not()", "enabled"]
          ignored_attribute.scan(/:([^:]*)/).flatten
        end

        # @param selector [String]
        # @return [Boolean]
        # @example
        #   multiple_selectors?('a.cls b#id') # => true
        #   multiple_selectors?('a.cls') # => false
        def multiple_selectors?(selector)
          normalize = selector.gsub(/(\\[>,+~]|\(.*\))/, '')
          normalize.match?(/[ >,+~]/)
        end

        # @param selector [String]
        # @return [String]
        # @example
        #   css_escape('some-id') # => some-id
        #   css_escape('some-id.with-priod') # => some-id\.with-priod
        # @reference
        #   https://github.com/mathiasbynens/CSS.escape/blob/master/css.escape.js
        def css_escape(selector) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          scanner = StringScanner.new(selector)
          result = +''

          # Special case: if the selector is of length 1 and
          # the first character is `-`
          if selector.length == 1 && scanner.peek(1) == '-'
            return "\\#{selector}"
          end

          until scanner.eos?
            # NULL character (U+0000)
            if scanner.scan(/\0/)
              result << "\uFFFD"
            # Control characters (U+0001 to U+001F, U+007F)
            elsif scanner.scan(/[\x01-\x1F\x7F]/)
              result << "\\#{scanner.matched.ord.to_s(16)} "
            # First character is a digit (U+0030 to U+0039)
            elsif scanner.pos.zero? && scanner.scan(/\d/)
              result << "\\#{scanner.matched.ord.to_s(16)} "
            # Second character is a digit and first is `-`
            elsif scanner.pos == 1 && scanner.scan(/\d/) &&
                scanner.pre_match == '-'
              result << "\\#{scanner.matched.ord.to_s(16)} "
            # Alphanumeric characters, `-`, `_`
            elsif scanner.scan(/[a-zA-Z0-9\-_]/)
              result << scanner.matched
            # Any other characters, escape them
            elsif scanner.scan(/./)
              result << "\\#{scanner.matched}"
            end
          end

          result
        end
      end
    end
  end
end
