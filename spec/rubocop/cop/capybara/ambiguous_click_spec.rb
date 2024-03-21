# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::AmbiguousClick do
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
