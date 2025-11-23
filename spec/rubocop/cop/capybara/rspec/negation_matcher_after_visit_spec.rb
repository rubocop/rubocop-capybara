# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RSpec::NegationMatcherAfterVisit,
               :config do
  it 'registers an offense when using `have_no_*` after ' \
     'immediately `visit` method call' do
    expect_offense(<<~RUBY)
      visit foo_path
      expect(page).to have_no_link('bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use negation matcher immediately after visit.
    RUBY
  end

  it 'registers an offense when using `not_to` with `have_*` after ' \
     'immediately `visit` method call' do
    expect_offense(<<~RUBY)
      visit foo_path
      expect(page).not_to have_link('bar')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use negation matcher immediately after visit.
    RUBY
  end

  it 'does not register an offense when using positive matchers after ' \
     'immediately `visit` method call' do
    expect_no_offenses(<<~RUBY)
      visit foo_path
      expect(page).to have_css('a')
      expect(page).to have_no_link('bar')
    RUBY
  end
end
