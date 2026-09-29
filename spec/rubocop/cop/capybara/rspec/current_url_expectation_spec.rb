# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::RSpec::CurrentUrlExpectation do
  it 'waits for literal, dynamic, and regexp URL expectations' do
    expect_offense(<<~RUBY)
      expect(page.current_url).to eq('https://example.com/login')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).to eq(expected_url)
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(current_url).to match(%r{/login})
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_current_path('https://example.com/login')
      expect(page).to have_current_path(expected_url)
      expect(page).to have_current_path(%r{/login}, url: true)
    RUBY
  end

  it 'uses the explicit negative matcher for negated expectations' do
    expect_offense(<<~RUBY)
      expect(page.current_url).not_to match(/login/)
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(current_url).to_not eq(expected_url)
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_no_current_path(/login/, url: true)
      expect(page).to have_no_current_path(expected_url)
    RUBY
  end

  it 'converts static string match patterns to regular expressions' do
    expect_offense(<<~RUBY)
      expect(page.current_url).to match('login')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).not_to match('admin')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_current_path(/login/, url: true)
      expect(page).to have_no_current_path(/admin/, url: true)
    RUBY
  end

  it 'reports substring and prefix/suffix checks without correcting them' do
    expect_offense(<<~RUBY)
      expect(page.current_url).to include('/login')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).to start_with('https://')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).to end_with('/login')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).to match(pattern)
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).to match(`printf login`)
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
      expect(page.current_url).to match('[')
      ^^^^^^ Use `have_current_path` on `page` to wait for the URL.
    RUBY

    expect_no_corrections
  end

  it 'ignores unrelated methods and unsupported matcher forms' do
    expect_no_offenses(<<~RUBY)
      expect(current_url)
      expect(page).to have_current_path('/login')
      expect(page.current_path).to eq('/login')
      expect(object.current_url).to eq('https://example.com/login')
      expect(page.current_url).to be('https://example.com/login')
      expect(page.current_url).to include(variable)
    RUBY
  end

  it 'ignores a bare URL read' do
    expect_no_offenses('expect(current_url)')
  end

  context 'with trailing comma correction enabled' do
    let(:other_cops) do
      style_config = RuboCop::ConfigLoader.default_configuration.for_cop(
        'Style/TrailingCommaInArguments'
      )
      {
        'Style/TrailingCommaInArguments' =>
          style_config.merge('EnforcedStyleForMultiline' => 'comma')
      }
    end

    it 'keeps the corrected URL expectation syntactically valid' do
      source = "expect(current_url).to match(\n  'login'\n)\n"
      team = RuboCop::Cop::Team.mobilize(
        [RuboCop::Cop::Style::TrailingCommaInArguments, described_class],
        config, autocorrect: true
      )
      team.defer_corrections = true
      team.investigate(RuboCop::ProcessedSource.new(source, 3.3, 'spec.rb'))

      corrected = RuboCop::ProcessedSource.new(
        team.updated_source, 3.3, 'spec.rb'
      )
      expect(corrected).to be_valid_syntax
    end
  end
end
