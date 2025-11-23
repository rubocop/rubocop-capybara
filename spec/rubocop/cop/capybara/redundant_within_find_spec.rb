# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RedundantWithinFind, :config do
  it 'registers an offense when using `within find(...)`' do
    expect_offense(<<~RUBY)
      within find('foo.bar') do
             ^^^^^^^^^^^^^^^ Redundant `within find(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within 'foo.bar' do
      end
    RUBY
  end

  it 'registers an offense when using `within(find ...)`' do
    expect_offense(<<~RUBY)
      within(find 'foo.bar') do
             ^^^^^^^^^^^^^^ Redundant `within find(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within('foo.bar') do
      end
    RUBY
  end

  it 'registers an offense when using `within find(...)` with other argument' do
    expect_offense(<<~RUBY)
      within find('foo.bar', visible: false) do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within 'foo.bar', visible: false do
      end
    RUBY
  end

  it 'registers an offense when using `within find_by_id(...)`' do
    expect_offense(<<~RUBY)
      within find_by_id('foo') do
             ^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within '#foo' do
      end
    RUBY
  end

  it 'registers an offense when using `within(find_by_id ...)`' do
    expect_offense(<<~RUBY)
      within(find_by_id 'foo') do
             ^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within('#foo') do
      end
    RUBY
  end

  it 'registers an offense when using `within find_by_id("foo.bar")`' do
    expect_offense(<<~RUBY)
      within find_by_id('foo.bar') do
             ^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
      within find_by_id("foo.bar") do
             ^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~'RUBY')
      within '#foo\.bar' do
      end
      within "#foo\\.bar" do
      end
    RUBY
  end

  it 'registers an offense when using `within find_by_id(...)` with ' \
     'other argument' do
    expect_offense(<<~RUBY)
      within find_by_id('foo', visible: false) do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within '#foo', visible: false do
      end
    RUBY
  end

  it 'registers an offense when using `within find_by_id(variable)`' do
    expect_offense(<<~RUBY)
      within find_by_id(id_variable) do
             ^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within id_variable do
      end
    RUBY
  end

  it 'does not register an offense when using `within` without `find`' do
    expect_no_offenses(<<~RUBY)
      within 'foo.bar' do
      end
    RUBY
  end
end
