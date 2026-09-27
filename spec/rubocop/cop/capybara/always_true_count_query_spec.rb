# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::AlwaysTrueCountQuery do
  it 'reports positive assertions and predicates with only minimum zero' do
    expect_offense(<<~RUBY)
      expect(page).to have_css('.item', minimum: 0)
                                        ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
      page.assert_selector('.item', minimum: 0)
                                    ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
      has_link?('Home', minimum: 0)
                        ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
      page.must_have_button('Save', minimum: 0)
                                    ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
      expect(page).to have_css('.item', minimum: 0, maximum: nil)
                                        ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
      expect(page).to have_css('.item', minimum: 0, count: nil)
                                        ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
      expect(page).to have_css('.item', minimum: 0, between: nil)
                                        ^^^^^^^^^^ `minimum: 0` makes this positive query succeed with no matches.
    RUBY

    expect_no_corrections
  end

  it 'leaves meaningful count queries and negative expectations alone' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_css('.item')
      expect(page).to have_css('.item', minimum: 0, maximum: 2)
      expect(page).to have_css('.item', minimum: 0, count: 1)
      expect(page).to have_css('.item', minimum: 0, between: 0..2)
      expect(page).not_to have_css('.item', minimum: 0)
      expect(page).to have_no_css('.item', minimum: 0)
      all('.item', minimum: 0)
      first('.item', minimum: 0)
    RUBY
  end

  it 'ignores ambiguous options and unrelated methods' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_css('.item', minimum: limit)
      expect(page).to have_css('.item', minimum: 0, **options)
      expect(page).to have_css('.item', minimum: 0, minimum: 1)
      expect(page).to have_css('.item', { minimum: 0 })
      matcher = have_css('.item', minimum: 0)
      object.has_css?('.item', minimum: 0)
    RUBY
  end
end
