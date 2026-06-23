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
          attrs.filter_map { |key, value| "#{key}: #{value}" }.join(', ')
        end

        def replaced_arguments(arg, id)
          attrs = CssSelector.attributes(arg).reject { |key, _| key == 'id' }
          options = options(attrs)
          options.empty? ? id : "#{id}, #{options}"
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
      #   find('input[placeholder="Email"]')
      #   find(:css, 'input[type="checkbox"]')
      #
      #   # good
      #   find_by_id('some-id')
      #   find_field(placeholder: 'Email')
      #   find_field(type: 'checkbox')
      #
      class SpecificFinders < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        RESTRICT_ON_SEND = %i[find].freeze

        # @!method find_argument(node)
        def_node_matcher :find_argument, <<~PATTERN
          (send _ :find $(sym {:css :id})? (str $_) ...)
        PATTERN

        # @!method class_options(node)
        def_node_search :class_options, <<~PATTERN
          (pair (sym :class) $_ ...)
        PATTERN

        def on_send(node)
          find_argument(node) do |sym, arg|
            next if SpecificFindersHelp.unsupported_selector?(arg)

            handle_find(node, sym, arg)
          end
        end

        private

        def handle_find(node, sym, arg)
          if SpecificFindersHelp.field_selector?(arg)
            on_field(node, sym, arg)
          elsif attribute?(arg)
            on_attr(node, sym, arg)
          elsif CssSelector.id?(arg)
            on_id(node, sym, arg)
          elsif sym.first&.value == :id
            on_sym_id(node, sym, arg)
          end
        end

        def on_attr(node, sym, arg)
          attrs = CssSelector.attributes(arg)
          return unless (id = attrs['id'])
          return if attrs['class']

          register_id_offense(
            node, sym, SpecificFindersHelp.replaced_arguments(arg, id)
          )
        end

        def on_id(node, sym, arg)
          return if CssSelector.attributes(arg).any?

          id = CssSelector.id(arg)
          register_id_offense(node, sym, "'#{id}'",
                              CssSelector.classes(arg.sub("##{id}", '')))
        end

        def on_sym_id(node, sym, id)
          register_id_offense(node, sym, "'#{id}'")
        end

        def on_field(node, sym, arg)
          add_offense(
            offense_range(node),
            message: SpecificFindersHelp.message('find_field')
          ) do |corrector|
            corrector.replace(node.loc.selector, 'find_field')
            arguments = SpecificFindersHelp.options(CssSelector.attributes(arg))
            corrector.replace(node.first_argument, arguments)
            corrector.remove(deletion_range(node)) unless sym.empty?
          end
        end

        def attribute?(arg)
          CssSelector.attribute?(arg) &&
            CapybaraHelp.common_attributes?(arg)
        end

        def register_id_offense(node, sym, id, classes = [])
          add_offense(
            offense_range(node),
            message: SpecificFindersHelp.message('find_by_id')
          ) do |corrector|
            corrector.replace(node.loc.selector, 'find_by_id')
            corrector.replace(node.first_argument, id.delete('\\'))
            has_classes = classes.compact.any?
            autocorrect_classes(corrector, node, classes) if has_classes
            corrector.remove(deletion_range(node)) unless sym.empty?
          end
        end

        def deletion_range(node)
          range_between(node.first_argument.source_range.end_pos,
                        node.arguments[1].source_range.end_pos)
        end

        def autocorrect_classes(corrector, node, classes)
          if (options = class_options(node).first)
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
