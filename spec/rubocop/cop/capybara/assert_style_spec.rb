# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::AssertStyle do
  it 'registers an offense when using `assert_style`' do
    expect_offense(<<~RUBY)
      page.find(:css, '#first').assert_style(display: 'block')
                                ^^^^^^^^^^^^ Use `assert_matches_style` instead of `assert_style`.
    RUBY

    expect_correction(<<~RUBY)
      page.find(:css, '#first').assert_matches_style(display: 'block')
    RUBY
  end

  it 'does not register an offense when using `assert_matches_style`' do
    expect_no_offenses(<<~RUBY)
      page.find(:css, '#first').assert_matches_style(display: 'block')
    RUBY
  end
end
