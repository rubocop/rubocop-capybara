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
      within :id, 'foo' do
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
      within(:id, 'foo') do
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

    expect_correction(<<~RUBY)
      within :id, 'foo.bar' do
      end
      within :id, "foo.bar" do
      end
    RUBY
  end

  it 'preserves ids that need CSS escaping' do
    expect_offense(<<~RUBY)
      within find_by_id('1st-row') do
             ^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
      within find_by_id('user:name') do
             ^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within :id, '1st-row' do
      end
      within :id, 'user:name' do
      end
    RUBY
  end

  it 'preserves alternative string literal syntax' do
    expect_offense(<<~RUBY)
      within find_by_id(%q(foo.bar)) do
             ^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within :id, %q(foo.bar) do
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
      within :id, 'foo', visible: false do
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
      within :id, id_variable do
      end
    RUBY
  end

  it 'registers an offense when using `within find_by_id(...)` with ' \
     'a dynamic id and other argument' do
    expect_offense(<<~RUBY)
      within find_by_id(dom_id(user), visible: :all) do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~RUBY)
      within :id, dom_id(user), visible: :all do
      end
    RUBY
  end

  it 'registers an offense when using `within find_by_id(...)` with ' \
     'an interpolated id' do
    expect_offense(<<~'RUBY')
      within find_by_id("user_#{user.id}") do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Redundant `within find_by_id(...)` call detected.
      end
    RUBY

    expect_correction(<<~'RUBY')
      within :id, "user_#{user.id}" do
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
