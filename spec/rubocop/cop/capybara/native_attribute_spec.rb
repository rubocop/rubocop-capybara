# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::NativeAttribute do
  it 'registers and corrects an offense with a symbol attribute' do
    expect_offense(<<~RUBY)
      find('.item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      find('.item')[:id]
    RUBY
  end

  it 'registers and corrects an offense with a receiver and string attribute' do
    expect_offense(<<~RUBY)
      page.find('.item').native.attribute('aria-label')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      page.find('.item')['aria-label']
    RUBY
  end

  it 'registers offenses for other element finders' do
    expect_offense(<<~RUBY)
      first('.item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
      find('.outer').ancestor('.item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
      find('.outer').sibling('.item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
      find_button('Save').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
      find_by_id('item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
      find_field('Name').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
      find_link('Home').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      first('.item')[:id]
      find('.outer').ancestor('.item')[:id]
      find('.outer').sibling('.item')[:id]
      find_button('Save')[:id]
      find_by_id('item')[:id]
      find_field('Name')[:id]
      find_link('Home')[:id]
    RUBY
  end

  it 'does not register an offense for an unrelated object' do
    expect_no_offenses(<<~RUBY)
      object.native.attribute(:id)
      records.first.native.attribute(:id)
      records.first(2).native.attribute(:id)
      collection.find { |item| item.active? }.native.attribute(:id)
      element.ancestor('.item').native.attribute(:id)
    RUBY
  end

  it 'does not register an offense for a dynamic attribute' do
    expect_no_offenses(<<~RUBY)
      find('.item').native.attribute(attribute_name)
    RUBY
  end

  it 'preserves parentheses around a command-style finder' do
    expect_offense(<<~RUBY)
      (find '.item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      (find '.item')[:id]
    RUBY
  end

  it 'handles a finder with a filter block' do
    expect_offense(<<~RUBY)
      find('.item') { _1.visible? }.native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      find('.item') { _1.visible? }[:id]
    RUBY
  end

  it 'handles safe navigation' do
    expect_offense(<<~RUBY)
      page&.find('.item')&.native&.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      page&.find('.item')&.[](:id)
    RUBY
  end

  it 'ignores finders on constants and literal collections' do
    expect_no_offenses(<<~RUBY)
      Model.find(1).native.attribute(:id)
      [object].first.native.attribute(:id)
    RUBY
  end

  it 'preserves a non-safe native call before safe attribute access' do
    expect_offense(<<~RUBY)
      first('.item').native&.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      first('.item')[:id]
    RUBY
  end

  it 'preserves comments in the attribute call' do
    expect_offense(<<~RUBY)
      find('.item').native.attribute(
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
        # Keep this explanation.
        :id
      )
    RUBY

    expect_no_corrections
  end

  it 'preserves heredocs with a separate closing parenthesis' do
    expect_offense(<<~RUBY)
      find('.item').native.attribute(
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
        <<~ATTR
          id
        ATTR
      )
    RUBY

    expect_no_corrections
  end

  it 'recognizes explicit Capybara sessions' do
    expect_offense(<<~RUBY)
      Capybara.current_session.find('.item').native.attribute(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Element#[]` instead of driver-specific `native.attribute`.
    RUBY

    expect_correction(<<~RUBY)
      Capybara.current_session.find('.item')[:id]
    RUBY
  end
end
