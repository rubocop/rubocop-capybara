# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::ChainedFind, :config do
  it 'registers an offense when using chained find with page' do
    expect_offense(<<~RUBY)
      page.find('#foo').find('.bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find('#foo .bar')` instead of chaining `find` methods.
    RUBY

    expect_correction(<<~RUBY)
      page.find('#foo .bar')
    RUBY
  end

  it 'registers an offense when using chained find without receiver' do
    expect_offense(<<~RUBY)
      find('#foo').find('.bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find('#foo .bar')` instead of chaining `find` methods.
    RUBY

    expect_correction(<<~RUBY)
      find('#foo .bar')
    RUBY
  end

  it 'registers an offense when using chained find with element' do
    expect_offense(<<~RUBY)
      element = find('#container')
      element.find('.parent').find('.child')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find('.parent .child')` instead of chaining `find` methods.
    RUBY

    expect_correction(<<~RUBY)
      element = find('#container')
      element.find('.parent .child')
    RUBY
  end

  it 'does not register an offense for chained Enumerable#find calls' do
    expect_no_offenses(<<~RUBY)
      items.find { |item| item.active? }.find { |item| item.ready? }
    RUBY
  end

  it 'does not register an offense for a non-Capybara find chain' do
    expect_no_offenses(<<~RUBY)
      tree.find('parent').find('child')
    RUBY
  end

  it 'does not register an offense for a typed second selector' do
    expect_no_offenses(<<~RUBY)
      find('#form').find(:button, 'Save')
    RUBY
  end

  it 'does not register an offense when the first find uses a typed selector' do
    expect_no_offenses(<<~RUBY)
      find(:button, 'Save').find('.label')
    RUBY
  end

  it 'registers an offense for triple chained find' do
    expect_offense(<<~RUBY)
      page.find('.a').find('.b').find('.c')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find('.a .b')` instead of chaining `find` methods.
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find('.a .b .c')` instead of chaining `find` methods.
    RUBY

    expect_correction(<<~RUBY)
      page.find('.a .b .c')
    RUBY
  end

  it 'registers an offense but does not autocorrect when first ' \
     'find has options' do
    expect_offense(<<~RUBY)
      page.find('#foo', text: 'baz').find('.bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
    RUBY

    expect_no_corrections
  end

  it 'registers an offense but does not autocorrect when second ' \
     'find has options' do
    expect_offense(<<~RUBY)
      page.find('#foo').find('.bar', visible: true)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
    RUBY

    expect_no_corrections
  end

  it 'registers an offense but does not autocorrect when both ' \
     'finds have options' do
    expect_offense(<<~RUBY)
      page.find('#foo', text: 'baz').find('.bar', match: :first)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
    RUBY

    expect_no_corrections
  end

  it 'registers an offense but does not autocorrect when find has a block' do
    expect_offense(<<~RUBY)
      page.find('#foo') { |el| el.text }.find('.bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
    RUBY

    expect_no_corrections
  end

  it 'does not autocorrect comma selectors' do
    expect_offense(<<~RUBY)
      page.find('.foo, .bar').find('.baz')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
    RUBY

    expect_no_corrections
  end

  it 'registers an offense but does not autocorrect when selectors use XPath' do
    expect_offense(<<~RUBY)
      page.find('#foo').find('//bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
    RUBY

    expect_no_corrections
  end

  context 'when DefaultSelector is xpath' do
    let(:cop_config) { { 'DefaultSelector' => 'xpath' } }

    it 'registers an offense without combining XPath selectors as CSS' do
      expect_offense(<<~RUBY)
        page.find('section').find('a')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
      RUBY

      expect_no_corrections
    end
  end

  context 'when RuboCop removes a null DefaultSelector' do
    let(:cur_cop_config) { super().reject { |key| key == 'DefaultSelector' } }

    it 'registers an offense without combining selectors' do
      expect_offense(<<~RUBY)
        page.find('section').find('a')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid chaining `find` methods. Combine the selectors into a single `find` call.
      RUBY

      expect_no_corrections
    end
  end

  it 'preserves quotes when autocorrecting a selector' do
    expect_offense(<<~RUBY)
      page.find("it's").find('.bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find("it's .bar")` instead of chaining `find` methods.
    RUBY

    expect_correction(<<~RUBY)
      page.find("it's .bar")
    RUBY
  end

  it 'autocorrects safe-navigation chains' do
    expect_offense(<<~RUBY)
      page&.find('#foo')&.find('.bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `find('#foo .bar')` instead of chaining `find` methods.
    RUBY

    expect_correction(<<~RUBY)
      page&.find('#foo .bar')
    RUBY
  end

  it 'does not register an offense when using single find' do
    expect_no_offenses(<<~RUBY)
      page.find('#foo')
    RUBY
  end

  it 'does not register an offense when using find with combined selector' do
    expect_no_offenses(<<~RUBY)
      page.find('#foo .bar')
    RUBY
  end

  it 'does not register an offense when find is followed by another method' do
    expect_no_offenses(<<~RUBY)
      page.find('#foo').click
    RUBY
  end

  it 'does not register an offense when other method is chained with find' do
    expect_no_offenses(<<~RUBY)
      other_method('#foo').find('.bar')
    RUBY
  end
end
