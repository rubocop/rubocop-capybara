# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
      # Help methods for SpecificFinders.
      # @api private
      module SpecificFindersHelp
        MESSAGE = 'Prefer `%<good_finder>s` over `find`.'
        FIELD_OPTIONS = CapybaraHelp::SPECIFIC_OPTIONS['field']
        FIELD_SELECTOR_PATTERN = /\Ainput(?:\[.+\])+\z/.freeze

        module_function

        def field_selector?(arg)
          return false unless FIELD_SELECTOR_PATTERN.match?(arg)

          attrs = CssSelector.attributes(arg)
          CapybaraHelp.replaceable_attributes?(attrs) &&
            attrs.keys.all? { |attr| FIELD_OPTIONS.include?(attr) }
        end

        def options(attrs)
          attrs.filter_map { |key, value| "#{key}: #{yield(value)}" }.join(', ')
        end

        def unsupported_selector?(arg)
          CssSelector.pseudo_classes(arg).any? ||
            CssSelector.multiple_selectors?(arg)
        end

        def message(finder)
          format(MESSAGE, good_finder: finder)
        end
      end

      # Checks if there is a more specific finder offered by Capybara.
      #
      # @example
      #   # bad
      #   find('#some-id')
      #   find('[id=some-id]')
      #   find(:css, '#some-id')
      #   find(:id, 'some-id')
      #   find(:link, 'Home')
      #   find(:field, 'Name')
      #   find('input[placeholder="Email"]')
      #   find(:css, 'input[type="checkbox"]')
      #
      #   # good
      #   find_by_id('some-id')
      #   find_link('Home')
      #   find_field('Name')
      #   find_field(placeholder: 'Email')
      #   find_field(type: 'checkbox')
      #
      class SpecificFinders < RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `%<replacement>s` over `find`.'
        RESTRICT_ON_SEND = %i[find].freeze

        # @!method find_argument(node)
        def_node_matcher :find_argument, <<~PATTERN
          (send _ :find $(sym {:css :id :link :field})? (str $_) ...)
        PATTERN

        # @!method class_option(node)
        def_node_matcher :class_option, <<~PATTERN
          (send _ :find ... (hash <(pair (sym :class) $_) ...>))
        PATTERN

        def on_send(node) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          find_argument(node) do |sym, arg|
            next if SpecificFindersHelp.unsupported_selector?(arg)

            handle_find(node, sym, arg)
          end
        end

        private

        def selector?(sym)
          %i[link field].include?(sym.first.value)
        end

        def id_symbol?(sym)
          sym.first&.value == :id
        end

        def selector_symbol?(sym)
          sym.first && selector?(sym)
        end

        def on_sym_selector(node, sym)
          replacement = "find_#{sym.first.value}"
          register_selector_offense(node, replacement)
        end

        def register_selector_offense(node, replacement)
          message = format(MSG, replacement: replacement)
          add_offense(offense_range(node), message: message) do |corrector|
            corrector.replace(node.loc.selector, replacement)
            remove_selector_argument(corrector, node)
          end
        end

        def remove_selector_argument(corrector, node)
          range = range_between(node.first_argument.source_range.begin_pos,
                                node.arguments[1].source_range.begin_pos)
          corrector.remove(range)
        end

        def handle_find(node, sym, arg)
          if SpecificFindersHelp.field_selector?(arg)
            return on_field(node, sym, arg)
          end
          return on_attr(node, sym, arg) if attribute?(arg)
          return on_id(node, sym, arg) if CssSelector.id?(arg)
          return on_sym_id(node, sym, arg) if id_symbol?(sym)

          on_sym_selector(node, sym) if selector_symbol?(sym)
        end

        def on_attr(node, sym, arg)
          attrs = CssSelector.attributes(arg)
          return unless (id = attrs['id'])
          return if attrs['class']

          register_offense(node, sym, replaced_arguments(arg, id))
        end

        def on_id(node, sym, arg)
          return if CssSelector.attributes(arg).any?

          id = CssSelector.id(arg)
          register_offense(node, sym, ruby_literal(id.delete('\\')),
                           CssSelector.classes(arg.sub("##{id}", '')))
        end

        def on_sym_id(node, sym, id)
          register_offense(node, sym, ruby_literal(id.delete('\\')))
        end

        def on_field(node, sym, arg)
          add_offense(
            offense_range(node),
            message: SpecificFindersHelp.message('find_field')
          ) do |corrector|
            corrector.replace(node.loc.selector, 'find_field')
            corrector.replace(node.first_argument, field_options(arg))
            corrector.remove(deletion_range(node)) unless sym.empty?
          end
        end

        def field_options(arg)
          SpecificFindersHelp.options(CssSelector.attributes(arg)) do |value|
            ruby_literal(value)
          end
        end

        def attribute?(arg)
          CssSelector.attribute?(arg) &&
            CapybaraHelp.common_attributes?(arg)
        end

        def register_offense(node, sym, replacement, classes = [])
          message = format(MSG, replacement: 'find_by_id')
          add_offense(offense_range(node), message: message) do |corrector|
            corrector.replace(node.loc.selector, 'find_by_id')
            corrector.replace(node.first_argument, replacement)
            autocorrect_id_classes(corrector, node, classes)
            corrector.remove(deletion_range(node)) unless sym.empty?
          end
        end

        def autocorrect_id_classes(corrector, node, classes)
          autocorrect_classes(corrector, node, classes) if classes.compact.any?
        end

        def deletion_range(node)
          range_between(node.first_argument.source_range.end_pos,
                        node.arguments[1].source_range.end_pos)
        end

        def autocorrect_classes(corrector, node, classes)
          if (options = class_option(node))
            append_options(classes, options)
            corrector.replace(options, classes.to_s)
          else
            corrector.insert_after(node.first_argument,
                                   keyword_argument_class(classes))
          end
        end

        def append_options(classes, options)
          classes << options.value if options.str_type?
          options.each_value { |v| classes << v.value } if options.array_type?
        end

        def keyword_argument_class(classes)
          value = classes.size > 1 ? classes.to_s : "'#{classes.first}'"
          ", class: #{value}"
        end

        def replaced_arguments(arg, id)
          options = to_options(CssSelector.attributes(arg))
          id = ruby_literal(id.delete('\\'))

          options.empty? ? id : "#{id}, #{options}"
        end

        def to_options(attrs)
          attrs.each.filter_map do |key, value|
            next if key == 'id'

            "#{key}: #{ruby_literal(value)}"
          end.join(', ')
        end

        def ruby_literal(value)
          case value
          when String
            "'#{value.gsub(/['\\]/) { |char| "\\#{char}" }}'"
          when nil then 'nil'
          else
            value.to_s
          end
        end

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, end_pos(node))
        end

        def end_pos(node)
          node.loc.end ? node.loc.end.end_pos : node.source_range.end_pos
        end
      end
    end
  end
end
