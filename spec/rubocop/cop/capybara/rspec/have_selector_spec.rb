# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RSpec::HaveSelector, :config do
  let(:cop_config) do
    { 'DefaultSelector' => default_selector }
  end
  let(:default_selector) { 'css' }

  it 'registers an offense when using `have_selector`' do
    expect_offense(<<~RUBY)
      expect(foo).to have_selector('bar')
                     ^^^^^^^^^^^^^^^^^^^^ Use `have_css` instead of `have_selector`.
    RUBY

    expect_correction(<<~RUBY)
      expect(foo).to have_css('bar')
    RUBY
  end

  it 'registers an offense when using `have_selector` with `:css`' do
    expect_offense(<<~RUBY)
      expect(foo).to have_selector(:css, 'bar')
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `have_css` instead of `have_selector`.
    RUBY

    expect_correction(<<~RUBY)
      expect(foo).to have_css('bar')
    RUBY
  end

  it 'registers an offense when using `have_selector` with `:xpath`' do
    expect_offense(<<~RUBY)
      expect(foo).to have_selector(:xpath, 'bar')
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `have_xpath` instead of `have_selector`.
    RUBY

    expect_correction(<<~RUBY)
      expect(foo).to have_xpath('bar')
    RUBY
  end

  it 'does not register an offense when using `have_css`' do
    expect_no_offenses(<<~RUBY)
      expect(foo).to have_css('bar')
    RUBY
  end

  it 'does not register an offense when using `have_selector` with other sym' do
    expect_no_offenses(<<~RUBY)
      expect(foo).to have_selector(:foo, 'bar')
    RUBY
  end

  it 'registers an offense when using `have_selector` with `:css` ' \
     'and "#{bar}"' do
    expect_offense(<<~'RUBY')
      expect(foo).to have_selector(:css, "#{bar}")
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `have_css` instead of `have_selector`.
    RUBY

    expect_correction(<<~'RUBY')
      expect(foo).to have_css("#{bar}")
    RUBY
  end

  it 'registers an offense when using `have_selector` with ' \
     '"input[name=\'#{title}\']"' do
    expect_offense(<<~'RUBY')
      expect(foo).to have_selector("input[name='#{title}']")
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `have_css` instead of `have_selector`.
    RUBY

    expect_correction(<<~'RUBY')
      expect(foo).to have_css("input[name='#{title}']")
    RUBY
  end

  it 'registers no offense when no arguments are passed' do
    expect_no_offenses(<<~RUBY)
      expect(foo).to have_selector
    RUBY
  end

  context 'when DefaultSelector is xpath' do
    let(:default_selector) { 'xpath' }

    it 'registers an offense when using `have_selector`' do
      expect_offense(<<~RUBY)
        expect(foo).to have_selector('bar')
                       ^^^^^^^^^^^^^^^^^^^^ Use `have_xpath` instead of `have_selector`.
      RUBY

      expect_correction(<<~RUBY)
        expect(foo).to have_xpath('bar')
      RUBY
    end

    it 'registers an offense when using `have_selector` with `:xpath`' do
      expect_offense(<<~RUBY)
        expect(foo).to have_selector(:xpath, 'bar')
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `have_xpath` instead of `have_selector`.
      RUBY

      expect_correction(<<~RUBY)
        expect(foo).to have_xpath('bar')
      RUBY
    end

    it 'registers an offense when using `have_selector` with `:css`' do
      expect_offense(<<~RUBY)
        expect(foo).to have_selector(:css, 'bar')
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `have_css` instead of `have_selector`.
      RUBY

      expect_correction(<<~RUBY)
        expect(foo).to have_css('bar')
      RUBY
    end
  end
end
