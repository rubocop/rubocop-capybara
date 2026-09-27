# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RSpec::TitleExpectation do
  it 'uses waiting title matchers for string and regexp expectations' do
    expect_offense(<<~RUBY)
      expect(page.title).to eq('Dashboard')
      #{' ' * 7}^^^^^^^^^^ Use `have_title` on `page` to wait for the title.
      expect(page.title).to include('Dash')
      #{' ' * 7}^^^^^^^^^^ Use `have_title` on `page` to wait for the title.
      expect(page.title).to match(/Dash/)
      #{' ' * 7}^^^^^^^^^^ Use `have_title` on `page` to wait for the title.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_title('Dashboard', exact: true)
      expect(page).to have_title('Dash')
      expect(page).to have_title(/Dash/)
    RUBY
  end

  it 'preserves a negated expectation' do
    expect_offense(<<~RUBY)
      expect(page.title).not_to eq('Old')
      #{' ' * 7}^^^^^^^^^^ Use `have_title` on `page` to wait for the title.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).not_to have_title('Old', exact: true)
    RUBY
  end

  it 'ignores unknown title receivers and unsupported values' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_title('Dashboard')
      expect(record.title).to eq('Dashboard')
      expect(title).to eq('Dashboard')
      expect(page.title).to eq(value)
      expect(page.title).to include(/Dash/)
      expect(page.title).to match('Dash')
    RUBY
  end
end
