# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RSpec::FindElementValueEq do
  it 'registers an offense when using `find` element value with `eq`' do
    expect_offense(<<~RUBY)
      expect(find('input').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(find(:css, 'input').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(find('textarea').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(find(:css, 'textarea').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(page.find('input').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(page.find(:css, 'input').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_field(with: 'foobar')
      expect(page).to have_field(with: 'foobar')
      expect(page).to have_field(with: 'foobar')
      expect(page).to have_field(with: 'foobar')
      expect(page).to have_field(with: 'foobar')
      expect(page).to have_field(with: 'foobar')
    RUBY
  end

  it 'preserves receiver when using scoped `find` element value with `eq`' do
    expect_offense(<<~RUBY)
      expect(container.find('input').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(container.find(:css, 'input').value).to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
    RUBY

    expect_correction(<<~RUBY)
      expect(container).to have_field(with: 'foobar')
      expect(container).to have_field(with: 'foobar')
    RUBY
  end

  it 'registers an offense when using `find_field` value with `eq`' do
    expect_offense(<<~RUBY)
      expect(find_field('Email').value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(find(:field, 'Email').value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(page.find_field('Email').value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(page.find(:field, 'Email').value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(container.find_field('Email').value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(container.find(:field, 'Email').value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_field('Email', with: 'user@example.com')
      expect(page).to have_field('Email', with: 'user@example.com')
      expect(page).to have_field('Email', with: 'user@example.com')
      expect(page).to have_field('Email', with: 'user@example.com')
      expect(container).to have_field('Email', with: 'user@example.com')
      expect(container).to have_field('Email', with: 'user@example.com')
    RUBY
  end

  it 'registers an offense when using negated `find` element value with `eq`' do
    expect_offense(<<~RUBY)
      expect(find('input').value).not_to eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(find('input').value).to_not eq('foobar')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_no_field(with: 'foobar')
      expect(page).to have_no_field(with: 'foobar')
    RUBY
  end

  it 'preserves non-literal expected values' do
    expect_offense(<<~RUBY)
      expect(find('input').value).to eq(expected_value)
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_field(with: expected_value)
    RUBY
  end

  it 'wraps method call expected values without parentheses ' \
     'during autocorrection' do
    expect_offense(<<~RUBY)
      expect(find('input').value).to eq(expected_value :foo)
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
      expect(find_field(field_name :email).value).to eq('user@example.com')
      ^^^^^^ Prefer `have_field` over checking `find(...).value`.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_field(with: (expected_value :foo))
      expect(page).to have_field((field_name :email), with: 'user@example.com')
    RUBY
  end

  it 'does not register an offense when value expectation is not replaceable' do
    expect_no_offenses(<<~RUBY)
      expect(find('input.foo').value).to eq('foobar')
      expect(find('input', visible: false).value).to eq('foobar')
      expect(find_field('Email', disabled: true).value).to eq('foobar')
      expect(find('input').text).to eq('foobar')
      expect(find('input').value).to eql('foobar')
      expect(value).to eq('foobar')
    RUBY
  end
end
