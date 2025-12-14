# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RSpec::HaveContent do
  it 'registers an offense when using `have_content`' do
    expect_offense(<<~RUBY)
      expect(page).to have_content('text')
                      ^^^^^^^^^^^^ Prefer `have_text` over `have_content`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_text('text')
    RUBY
  end

  it 'registers an offense when using `have_no_content`' do
    expect_offense(<<~RUBY)
      expect(page).to have_no_content('capybara')
                      ^^^^^^^^^^^^^^^ Prefer `have_no_text` over `have_no_content`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_no_text('capybara')
    RUBY
  end

  it 'does not register an offense when using `have_text`' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_text('ruby')
    RUBY
  end

  it 'does not register an offense when using `have_no_text`' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_no_text('capybara')
    RUBY
  end

  it 'preserves arguments during autocorrection' do
    expect_offense(<<~RUBY)
      expect(page).to have_content('text', exact: true)
                      ^^^^^^^^^^^^ Prefer `have_text` over `have_content`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_text('text', exact: true)
    RUBY
  end
end
