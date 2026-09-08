# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::IneffectiveQueryOption, :config do
  it 'registers offenses for count options passed to singular finders' do
    expect_offense(<<~RUBY)
      find('.row', count: 3)
                   ^^^^^^^^ `count` has no effect when passed to `find`.
      find_button('Delete', minimum: 2)
                            ^^^^^^^^^^ `minimum` has no effect when passed to `find_button`.
      page.find_by_id('row', maximum: 3)
                             ^^^^^^^^^^ `maximum` has no effect when passed to `find_by_id`.
      page&.find_field('Name', between: 1..2)
                               ^^^^^^^^^^^^^ `between` has no effect when passed to `find_field`.
    RUBY

    expect_no_corrections
  end

  it 'registers and corrects `exact` on explicit CSS queries' do
    expect_offense(<<~RUBY)
      find(:css, '.item', exact: true)
                          ^^^^^^^^^^^ `exact` has no effect on CSS queries.
      page&.find(:css, '.item', exact: false)
                                ^^^^^^^^^^^^ `exact` has no effect on CSS queries.
      expect(page).to have_css('.item', exact: true)
                                        ^^^^^^^^^^^ `exact` has no effect on CSS queries.
      expect(page).to have_selector(:css, '.item', exact: true)
                                                   ^^^^^^^^^^^ `exact` has no effect on CSS queries.
    RUBY

    expect_correction(<<~RUBY)
      find(:css, '.item')
      page&.find(:css, '.item')
      expect(page).to have_css('.item')
      expect(page).to have_selector(:css, '.item')
    RUBY
  end

  it 'does not register `exact` when the selector is not explicitly CSS' do
    expect_no_offenses(<<~RUBY)
      find('.item', exact: true)
      find(:xpath, './/item', exact: true)
      find(:custom, '.item', exact: true)
      expect(page).to have_xpath('.//item', exact: true)
      expect(page).to have_selector(selector, '.item', exact: true)
    RUBY
  end

  it 'registers and corrects boolean `exact_text` with regexp `text`' do
    expect_offense(<<~RUBY)
      find('.item', text: /foo/, exact_text: true)
                                 ^^^^^^^^^^^^^^^^ `exact_text` has no effect when `text` is a regexp.
      expect(page).to have_css('.item', exact_text: false, text: %r{foo})
                                        ^^^^^^^^^^^^^^^^^ `exact_text` has no effect when `text` is a regexp.
    RUBY

    expect_correction(<<~RUBY)
      find('.item', text: /foo/)
      expect(page).to have_css('.item', text: %r{foo})
    RUBY
  end

  it 'does not register `exact_text` when it can affect the query' do
    expect_no_offenses(<<~RUBY)
      find('.item', text: 'foo', exact_text: true)
      find('.item', text: /foo/, exact_text: 'foo')
      find('.item', exact_text: /foo/)
      find('.item', text: pattern, exact_text: true)
      find(:custom, '.item', text: /foo/, exact_text: true)
      find(:custom, text: /foo/, exact_text: true)
      find(selector, '.item', text: /foo/, exact_text: true)
      expect(page).to have_text('foo', text: /foo/, exact_text: true)
      find('.item', text: /foo/, exact_text: true, **options)
      find('.item', text: /foo/, **options, exact_text: true)
    RUBY
  end

  it 'ignores keyword splats that could select a custom filter set' do
    expect_no_offenses(<<~RUBY)
      find('.item', **options, text: /foo/, exact_text: true)
    RUBY
  end

  it 'registers and corrects `match` for collections with built-in selectors' do
    expect_offense(<<~RUBY)
      all(:css, '.item', match: :first)
                         ^^^^^^^^^^^^^ `match` has no effect when passed to `all`.
      first(:button, 'Delete', match: :one)
                               ^^^^^^^^^^^ `match` has no effect when passed to `first`.
      page&.find_all(:xpath, './/item', match: :smart)
                                        ^^^^^^^^^^^^^ `match` has no effect when passed to `find_all`.
    RUBY

    expect_correction(<<~RUBY)
      all(:css, '.item')
      first(:button, 'Delete')
      page&.find_all(:xpath, './/item')
    RUBY
  end

  it 'does not register `match` when the selector may be custom' do
    expect_no_offenses(<<~RUBY)
      all('.item', match: :first)
      all(:custom, '.item', match: :first)
      first(selector, '.item', match: :one)
      find(:css, '.item', match: :one)
      all(:css, '.item', match: strategy)
      all(:css, '.item', match: :invalid)
    RUBY
  end

  it 'ignores match options with unknown keyword splats' do
    expect_no_offenses(<<~RUBY)
      all(:css, '.item', match: :first, **options)
      first(:css, '.item', **options, match: :one)
    RUBY
  end

  it 'registers and corrects count options shadowed by `count`' do
    expect_offense(<<~RUBY)
      expect(page).to have_css('.item', count: 3, minimum: 1, maximum: 4, between: 2..4)
                                                  ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
                                                              ^^^^^^^^^^ `maximum` has no effect when `count` is specified.
                                                                          ^^^^^^^^^^^^^ `between` has no effect when `count` is specified.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_css('.item', count: 3)
    RUBY
  end

  it 'registers shadowed count options for text queries' do
    expect_offense(<<~RUBY)
      expect(page).to have_text('foo', count: 2, minimum: 1)
                                                 ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
    RUBY

    expect_correction(<<~RUBY)
      expect(page).to have_text('foo', count: 2)
    RUBY
  end

  %w[
    assert_content assert_no_content refute_text refute_content
    must_have_text wont_have_text must_have_content wont_have_content
  ].each do |method|
    it "registers shadowed count options for `#{method}`" do
      expect_offense(<<~RUBY, method: method)
        %{method}('foo', count: 2, minimum: 1)
        _{method}                  ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
      RUBY

      expect_correction(<<~RUBY)
        #{method}('foo', count: 2)
      RUBY
    end
  end

  it 'does not register count options that can affect the query' do
    expect_no_offenses(<<~RUBY)
      all('.item', count: 3)
      all('.item', minimum: 1, maximum: 4, between: 2..4)
      all('.item', count: nil, minimum: 1)
      all('.item', count: false, minimum: 1)
      all('.item', count: expected_count, minimum: 1)
      all('.item', count: 3, minimum: 1, **options)
      all('.item', count: 3, **options, minimum: 1)
      all('.item', count: 3, minimum: 1)
      all(:custom, '.item', count: 3, minimum: 1)
      all(selector, '.item', count: 3, minimum: 1)
    RUBY
  end

  it 'registers shadowed count options with an explicit built-in selector' do
    expect_offense(<<~RUBY)
      all(:css, '.item', count: 3, minimum: 1)
                                   ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
    RUBY

    expect_correction(<<~RUBY)
      all(:css, '.item', count: 3)
    RUBY
  end

  it 'ignores count options with unknown keyword splats' do
    expect_no_offenses(<<~RUBY)
      all(:css, '.item', **options, count: 3, minimum: 1)
    RUBY
  end

  it 'does not register count options rejected by match queries' do
    expect_no_offenses(<<~RUBY)
      expect(page).to match_css('.item', count: 3, minimum: 1)
      page.matches_selector?(:css, '.item', count: 3, minimum: 1)
    RUBY
  end

  it 'ignores calls without statically known ineffective options' do
    expect_no_offenses(<<~RUBY)
      all
      all(:css, '.item', option => true)
      find('.item', exact_text: true)
    RUBY
  end

  it 'ignores explicit positional hashes' do
    expect_no_offenses(<<~RUBY)
      find('.row', { count: 3 })
      find(:css, '.item', { exact: true })
      find('.item', { text: /foo/, exact_text: true })
      all(:css, '.item', { match: :first })
      all('.item', { count: 3, minimum: 1 })
    RUBY
  end

  it 'does not autocorrect calls containing comments' do
    expect_offense(<<~RUBY)
      all(:css, '.item',
          visible: true, # Keep this comment.
          match: :first)
          ^^^^^^^^^^^^^ `match` has no effect when passed to `all`.
    RUBY

    expect_no_corrections
  end

  it 'corrects multiple kinds of ineffective options together' do
    expect_offense(<<~RUBY)
      all(:css, '.item', exact: true, text: /foo/, exact_text: true, match: :first, count: 3, minimum: 1)
                         ^^^^^^^^^^^ `exact` has no effect on CSS queries.
                                                   ^^^^^^^^^^^^^^^^ `exact_text` has no effect when `text` is a regexp.
                                                                     ^^^^^^^^^^^^^ `match` has no effect when passed to `all`.
                                                                                              ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
    RUBY

    expect_correction(<<~RUBY)
      all(:css, '.item', text: /foo/, count: 3)
    RUBY
  end

  it 'does not treat a symbol locator as a selector type' do
    expect_no_offenses(<<~RUBY)
      find_button(:css, exact: true)
      have_text(:css, exact: true)
      have_link(:css, exact: true)
    RUBY
  end

  it 'preserves side effects in ignored option values' do
    expect_offense(<<~RUBY)
      have_css('.item', count: 2, minimum: record_attempt)
                                  ^^^^^^^^^^^^^^^^^^^^^^^ `minimum` has no effect when `count` is specified.
      find(:css, '.item', exact: record_attempt)
                          ^^^^^^^^^^^^^^^^^^^^^ `exact` has no effect on CSS queries.
    RUBY

    expect_no_corrections
  end

  it 'preserves an overriding exact_text option' do
    expect_offense(<<~RUBY)
      find('.item', text: /foo/, exact_text: 'bar', exact_text: true)
                                                    ^^^^^^^^^^^^^^^^ `exact_text` has no effect when `text` is a regexp.
    RUBY

    expect_no_corrections
  end

  it 'does not treat custom filter options as ineffective' do
    expect_no_offenses(<<~RUBY)
      have_css('.item', filter_set: :custom, count: 2, minimum: 1)
      find(:css, '.item', filter_set: :custom, exact: true)
      all(:css, '.item', filter_set: :custom, match: :first)
    RUBY
  end

  it 'handles filter block arguments on assertions' do
    expect_offense(<<~RUBY)
      assert_css('.item', exact: true, &filter)
                          ^^^^^^^^^^^ `exact` has no effect on CSS queries.
    RUBY

    expect_correction(<<~RUBY)
      assert_css('.item', &filter)
    RUBY
  end

  it 'does not remove the last option leaving an orphaned comma' do
    expect_offense(<<~RUBY)
      all(:css, '.item', match: :one,)
                         ^^^^^^^^^^^ `match` has no effect when passed to `all`.
    RUBY

    expect_correction(<<~RUBY)
      all(:css, '.item',)
    RUBY
  end

  it 'corrects an option-only call and preserves a filter block' do
    expect_offense(<<~RUBY)
      have_css(exact: true,)
               ^^^^^^^^^^^ `exact` has no effect on CSS queries.
      have_css(exact: true, &filter)
               ^^^^^^^^^^^ `exact` has no effect on CSS queries.
    RUBY

    expect_correction(<<~RUBY)
      have_css()
      have_css(&filter)
    RUBY
  end

  it 'preserves heredocs in ineffective option values' do
    expect_offense(<<~RUBY)
      have_css('.item', count: 1, minimum: <<~COUNT)
                                  ^^^^^^^^^^^^^^^^^ `minimum` has no effect when `count` is specified.
        1
      COUNT
    RUBY

    expect_no_corrections
  end

  it 'ignores constants and literal receivers' do
    expect_no_offenses(<<~RUBY)
      Model.find(count: 1)
      [item].find(count: 1)
    RUBY
  end

  it 'ignores custom ancestor and sibling selectors' do
    expect_no_offenses(<<~RUBY)
      has_ancestor?(:custom, '.item', text: /foo/, exact_text: true)
      have_sibling(:custom, '.item', count: 2, minimum: 1)
    RUBY
  end

  it 'handles count options on specific assertions' do
    expect_offense(<<~RUBY)
      assert_link('Home', count: 2, minimum: 1)
                                    ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
    RUBY

    expect_correction(<<~RUBY)
      assert_link('Home', count: 2)
    RUBY
  end

  it 'ignores unknown receivers and custom singular selectors' do
    expect_no_offenses(<<~RUBY)
      records.find(count: 1)
      records.first(:css, '.item', match: :first)
      find(:custom, '.item', count: 1)
      find(selector, '.item', minimum: 1)
    RUBY
  end

  it 'ignores computed option keys that can override known options' do
    expect_no_offenses(<<~RUBY)
      have_css('.item', count: 1, minimum: 2, key => nil)
      find('.item', text: /foo/, exact_text: true, key => 'bar')
      find(:css, '.item', exact: true, key => :custom)
    RUBY
  end

  it 'preserves evaluation of composite literals' do
    expect_offense(<<~RUBY)
      have_css('.item', count: 1, minimum: [MissingConstant])
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^ `minimum` has no effect when `count` is specified.
      have_css('.item', count: 1, between: 1..'two')
                                  ^^^^^^^^^^^^^^^^^ `between` has no effect when `count` is specified.
    RUBY

    expect_no_corrections
  end

  it 'recognizes Capybara receivers through finder chains and parentheses' do
    expect_offense(<<~RUBY)
      (page).find('.outer') { _1.visible? }.has_css?('.item', exact: true)
                                                              ^^^^^^^^^^^ `exact` has no effect on CSS queries.
      ::Capybara.current_session.has_css?('.item', exact: true)
                                                   ^^^^^^^^^^^ `exact` has no effect on CSS queries.
    RUBY

    expect_correction(<<~RUBY)
      (page).find('.outer') { _1.visible? }.has_css?('.item')
      ::Capybara.current_session.has_css?('.item')
    RUBY
  end

  context 'with a custom default selector' do
    let(:cop_config) { { 'DefaultSelector' => 'custom' } }

    it 'ignores options that can be used by custom filters' do
      expect_no_offenses(<<~RUBY)
        find('.item', count: 1)
        find(count: 1)
        find('.item', text: /foo/, exact_text: true)
        have_selector('.item', text: /foo/, exact_text: false)
        all('.item', match: :first, count: 1, minimum: 2)
      RUBY
    end

    it 'still checks explicit built-in and text queries' do
      expect_offense(<<~RUBY)
        find(:css, '.item', exact: true)
                            ^^^^^^^^^^^ `exact` has no effect on CSS queries.
        have_text('foo', count: 1, minimum: 2)
                                   ^^^^^^^^^^ `minimum` has no effect when `count` is specified.
      RUBY

      expect_correction(<<~RUBY)
        find(:css, '.item')
        have_text('foo', count: 1)
      RUBY
    end
  end

  context 'with an unknown default selector' do
    let(:cop_config) { { 'DefaultSelector' => nil } }

    it 'does not infer a selector from the locator' do
      expect_no_offenses(<<~RUBY)
        find('.item', count: 1)
        find('.item', text: /foo/, exact_text: true)
      RUBY
    end
  end
end
