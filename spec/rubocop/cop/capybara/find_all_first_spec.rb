# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::FindAllFirst, :config do
  it 'registers an offense when using `all` with `first`' do
    expect_offense(<<~RUBY)
      all('a').first
      ^^^^^^^^^^^^^^ Use `first('a')`.
    RUBY

    expect_correction(<<~RUBY)
      first('a')
    RUBY
  end

  it 'registers an offense when using `all` with `[0]`' do
    expect_offense(<<~RUBY)
      all('a')[0]
      ^^^^^^^^^^^ Use `first('a')`.
    RUBY

    expect_correction(<<~RUBY)
      first('a')
    RUBY
  end

  it 'registers an offense when using `find` with `match: :first`' do
    expect_offense(<<~RUBY)
      find('a', match: :first)
      ^^^^^^^^^^^^^^^^^^^^^^^^ Use `first('a')`.
      find('a', text: 'b', match: :first)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `first('a', text: 'b')`.
    RUBY

    expect_correction(<<~RUBY)
      first('a')
      first('a', text: 'b')
    RUBY
  end

  it 'registers an offense when using `all` with `match: :first`' do
    expect_offense(<<~RUBY)
      all('a', match: :first)
      ^^^^^^^^^^^^^^^^^^^^^^^ Use `first('a')`.
      all('a', text: 'b', match: :first)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `first('a', text: 'b')`.
    RUBY

    expect_correction(<<~RUBY)
      first('a')
      first('a', text: 'b')
    RUBY
  end

  it 'registers an offense when using `all` with argument and `first`' do
    expect_offense(<<~RUBY)
      all('a', text: 'b')[0]
      ^^^^^^^^^^^^^^^^^^^^^^ Use `first('a', text: 'b')`.
    RUBY

    expect_correction(<<~RUBY)
      first('a', text: 'b')
    RUBY
  end

  it 'registers an offense when using `all` with `first` and receiver' do
    expect_offense(<<~RUBY)
      page.all('a').first
           ^^^^^^^^^^^^^^ Use `first('a')`.
    RUBY

    expect_correction(<<~RUBY)
      page.first('a')
    RUBY
  end

  it 'registers an offense when using nested `all` with `first` and receiver' do
    expect_offense(<<~RUBY)
      find('a')
        .all('div')
         ^^^^^^^^^^ Use `first('div')`.
          .first
    RUBY

    expect_correction(<<~RUBY)
      find('a')
        .first('div')
    RUBY
  end

  it 'does not register an offense when using `first`' do
    expect_no_offenses(<<~RUBY)
      first('a')
    RUBY
  end

  it 'does not register an offense when using `all` without `first`' do
    expect_no_offenses(<<~RUBY)
      all('a').map(&:text)
    RUBY
  end

  it 'does not register an offense when using `all` with `[1]`' do
    expect_no_offenses(<<~RUBY)
      all('a')[1]
    RUBY
  end

  it 'does not register an offense when using `all` with argument' \
     ' without `first`' do
    expect_no_offenses(<<~RUBY)
      all('a', text: 'b')
    RUBY
  end

  it 'does not register an offense when using no argument `all`' do
    expect_no_offenses(<<~RUBY)
      all.first
      all[0]
    RUBY
  end

  context 'when using logical operators' do
    it 'does not register an offense when using `all` with ' \
       '`[0]` and `||` operator' do
      expect_no_offenses(<<~RUBY)
        all('a')[0] || all('div')[0]
      RUBY
    end

    it 'does not register an offense when using `all` with ' \
       '`first` and `||` operator' do
      expect_no_offenses(<<~RUBY)
        all('a').first || all('div').first
      RUBY
    end

    it 'does not register an offense when using `all` with ' \
       '`[0]` and `&&` operator' do
      expect_no_offenses(<<~RUBY)
        all('a')[0] && all('div')[0]
      RUBY
    end

    it 'does not register an offense when using `all` with ' \
       '`first` and `&&` operator' do
      expect_no_offenses(<<~RUBY)
        all('a').first && all('div').first
      RUBY
    end

    it 'does not register an offense when using mixed ' \
       'logical operators' do
      expect_no_offenses(<<~RUBY)
        all('a')[0] || all('div').first && all('span')[0]
      RUBY
    end

    it 'does not register an offense when using logical operators' \
       'with parentheses' do
      expect_no_offenses(<<~RUBY)
        (all('a')[0] || all('div')[0]) && all('span').first
      RUBY
    end

    it 'does not register an offense when using logical operators' \
       'in assignment' do
      expect_no_offenses(<<~RUBY)
        element = all('a')[0] || all('div')[0]
      RUBY
    end

    it 'does not register an offense when using logical operators' \
       'in method call' do
      expect_no_offenses(<<~RUBY)
        do_something(all('a')[0] || all('div')[0])
        do_something(all('a').first || all('div').first)
      RUBY
    end
  end
end
