# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::VisibilityOption do
  it 'registers and corrects `visible: true`' do
    expect_offense(<<~RUBY)
      find('.menu', visible: true)
                    ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
    RUBY

    expect_correction(<<~RUBY)
      find('.menu', visible: :visible)
    RUBY
  end

  it 'registers but does not correct `visible: false`' do
    expect_offense(<<~RUBY)
      find('.menu', visible: false)
                    ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
    RUBY

    expect_no_corrections
  end

  it 'registers offenses for actions, predicates, and assertions' do
    expect_offense(<<~RUBY)
      click_button('Save', visible: false)
                           ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
      page.has_css?('.menu', visible: false)
                             ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
      page.assert_selector('.menu', visible: false)
                                    ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
    RUBY
  end

  it 'registers offenses for RSpec and Minitest matchers' do
    expect_offense(<<~RUBY)
      expect(page).to have_css('.menu', visible: false)
                                        ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
      page.must_have_css('.menu', visible: false)
                                  ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
    RUBY
  end

  it 'registers offenses for grouped and matching selectors' do
    expect_offense(<<~RUBY)
      expect(page).to have_all_of_selectors('.a', '.b', visible: false)
                                                        ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
      find('.menu').matches_css?('.menu', visible: true)
                                          ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
    RUBY
  end

  it 'does not register offenses for explicit visibility values' do
    expect_no_offenses(<<~RUBY)
      find('.menu', visible: :visible)
      find('.menu', visible: :all)
      find('.menu', visible: :hidden)
    RUBY
  end

  it 'does not register offenses for unrelated methods or options' do
    expect_no_offenses(<<~RUBY)
      render('.menu', visible: false)
      have_text('Menu', visible: true)
      find('.menu', obscured: false)
    RUBY
  end

  it 'handles an explicit filter block argument' do
    expect_offense(<<~RUBY)
      find('.menu', visible: true, &filter)
                    ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
    RUBY

    expect_correction(<<~RUBY)
      find('.menu', visible: :visible, &filter)
    RUBY
  end

  it 'handles repeated visibility keys' do
    expect_offense(<<~RUBY)
      find('.menu', visible: true, visible: false)
                    ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
                                   ^^^^^^^^^^^^^^ Use `:all` or `:hidden` instead of `false`.
    RUBY

    expect_correction(<<~RUBY)
      find('.menu', visible: :visible, visible: false)
    RUBY
  end

  it 'ignores positional hashes and non-Capybara receivers' do
    expect_no_offenses(<<~RUBY)
      find('.menu', { visible: true })
      Model.find(visible: true)
      [item].select(visible: false)
      records.find(visible: true)
      connection.select('query', visible: false)
      element.has_css?('.menu', visible: true)
    RUBY
  end

  it 'preserves comments and safe navigation' do
    expect_offense(<<~RUBY)
      page&.find('.menu', visible: true) # Keep this.
                          ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
    RUBY

    expect_correction(<<~RUBY)
      page&.find('.menu', visible: :visible) # Keep this.
    RUBY
  end

  it 'handles a parenthesized receiver' do
    expect_offense(<<~RUBY)
      (page).find('.menu', visible: true)
                           ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
    RUBY

    expect_correction(<<~RUBY)
      (page).find('.menu', visible: :visible)
    RUBY
  end

  it 'ignores options that may select custom visibility filters' do
    expect_no_offenses(<<~RUBY)
      find('.menu', visible: true, filter_set: :custom)
      have_css('.menu', filter_set: :custom, visible: false)
      find('.menu', **options, visible: true)
      find('.menu', visible: true, key => :custom)
    RUBY
  end

  it 'ignores explicit custom and dynamic selectors' do
    expect_no_offenses(<<~RUBY)
      find(:custom, '.menu', visible: true)
      find(selector, '.menu', visible: false)
      have_selector(:custom, visible: true)
      have_ancestor(:custom, '.menu', visible: true)
      assert_all_of_selectors(:custom, '.a', '.b', visible: true)
    RUBY
  end

  context 'with a custom default selector' do
    let(:cop_config) { { 'DefaultSelector' => 'custom' } }

    it 'ignores queries using the default selector' do
      expect_no_offenses(<<~RUBY)
        find('.menu', visible: true)
        find(visible: false)
        have_selector('.menu', visible: false)
        have_all_of_selectors('.a', '.b', visible: true)
      RUBY
    end

    it 'still checks explicitly selected built-in queries' do
      expect_offense(<<~RUBY)
        find(:css, '.menu', visible: true)
                            ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
        find_button('Save', visible: true)
                            ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
      RUBY

      expect_correction(<<~RUBY)
        find(:css, '.menu', visible: :visible)
        find_button('Save', visible: :visible)
      RUBY
    end
  end

  context 'with an unknown default selector' do
    let(:cop_config) { { 'DefaultSelector' => nil } }

    it 'does not infer a selector from the locator' do
      expect_no_offenses(<<~RUBY)
        find('.menu', visible: true)
      RUBY
    end
  end

  it 'does not mistake symbol locators for custom selectors' do
    expect_offense(<<~RUBY)
      find_button(:save, visible: true)
                         ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
      find(:css, '.menu', visible: true)
                          ^^^^^^^^^^^^^ Use `:visible` instead of `true`.
    RUBY

    expect_correction(<<~RUBY)
      find_button(:save, visible: :visible)
      find(:css, '.menu', visible: :visible)
    RUBY
  end
end
