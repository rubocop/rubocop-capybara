# frozen_string_literal: true

module RuboCop
  module Cop
    module Capybara
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
      #
      #   # good
      #   find_by_id('some-id')
      #   find_link('Home')
      #   find_field('Name')
      #
      class SpecificFinders < ::RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `%<replacement>s` over `find`.'
        RESTRICT_ON_SEND = %i[find].freeze

        # @!method find_argument(node)
        def_node_matcher :find_argument, <<~PATTERN
          (send _ :find $(sym {:css :id :link :field})? (str $_) ...)
        PATTERN

        # @!method find_argument_without_locator(node)
        def_node_matcher :find_argument_without_locator, <<~PATTERN
          (send _ :find $(sym {:link :field}))
        PATTERN

        # @!method class_options(node)
        def_node_search :class_options, <<~PATTERN
          (pair (sym :class) $_ ...)
        PATTERN

        def on_send(node) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          find_argument(node) do |sym, arg|
            next if CssSelector.pseudo_classes(arg).any?
            next if CssSelector.multiple_selectors?(arg)

            on_attr(node, sym, arg) if attribute?(arg)
            on_id(node, sym, arg) if CssSelector.id?(arg)
            on_sym_id(node, sym, arg) if sym.first&.value == :id
            on_sym_selector(node, sym) if sym.first && selector?(sym)
          end
        end

        private

        def selector?(sym)
          %i[link field].include?(sym.first.value)
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
          if node.arguments.size == 1
            corrector.remove(node.first_argument)
          else
            range = range_between(node.first_argument.source_range.begin_pos,
                                  node.arguments[1].source_range.begin_pos)
            corrector.remove(range)
          end
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
          register_offense(node, sym, "'#{id}'",
                           CssSelector.classes(arg.sub("##{id}", '')))
        end

        def on_sym_id(node, sym, id)
          register_offense(node, sym, "'#{id}'")
        end

        def attribute?(arg)
          CssSelector.attribute?(arg) &&
            CapybaraHelp.common_attributes?(arg)
        end

        def register_offense(node, sym, id, classes = [])
          message = format(MSG, replacement: 'find_by_id')
          add_offense(offense_range(node), message: message) do |corrector|
            corrector.replace(node.loc.selector, 'find_by_id')
            corrector.replace(node.first_argument, id.delete('\\'))
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

        def replaced_arguments(arg, id)
          options = to_options(CssSelector.attributes(arg))
          options.empty? ? id : "#{id}, #{options}"
        end

        def to_options(attrs)
          attrs.each.filter_map do |key, value|
            next if key == 'id'

            "#{key}: #{value}"
          end.join(', ')
        end

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, end_pos(node))
        end

        def end_pos(node)
          if node.loc.end
            node.loc.end.end_pos
          else
            node.source_range.end_pos
          end
        end
      end
    end
  end
end
