# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::ClickLinkOrButtonStyle do
  let(:cop_config) { { 'EnforcedStyle' => enforced_style } }
  let(:enforced_style) { 'strict' }

  context 'when EnforcedStyle is `strict`' do
    let(:enforced_style) { 'strict' }

    it 'registers an offense when using `click_link_or_button`' do
      expect_offense(<<~RUBY)
        click_link_or_button('foo')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `click_link` or `click_button` instead of `click_link_or_button`.
      RUBY
    end

    it 'registers an offense when using `click_on`' do
      expect_offense(<<~RUBY)
        click_on('foo')
        ^^^^^^^^^^^^^^^ Use `click_link` or `click_button` instead of `click_on`.
      RUBY
    end

    it 'does not register an offense when using `click_link`' do
      expect_no_offenses(<<~RUBY)
        click_link('foo')
      RUBY
    end

    it 'does not register an offense when using `click_button`' do
      expect_no_offenses(<<~RUBY)
        click_button('foo')
      RUBY
    end
  end

  context 'when EnforcedStyle is `link_or_button`' do
    let(:enforced_style) { 'link_or_button' }

    it 'registers an offense when using `click_link`' do
      expect_offense(<<~RUBY)
        click_link('foo')
        ^^^^^^^^^^^^^^^^^ Use `click_link_or_button` or `click_on` instead of `click_link`.
      RUBY
    end

    it 'registers an offense when using `click_button`' do
      expect_offense(<<~RUBY)
        click_button('foo')
        ^^^^^^^^^^^^^^^^^^^ Use `click_link_or_button` or `click_on` instead of `click_button`.
      RUBY
    end

    it 'does not register an offense when using `click_link_or_button`' do
      expect_no_offenses(<<~RUBY)
        click_link_or_button('foo')
      RUBY
    end

    it 'does not register an offense when using `click_on`' do
      expect_no_offenses(<<~RUBY)
        click_on('foo')
      RUBY
    end
  end
end
