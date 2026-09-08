# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::QueryMethods do
  it 'lists singular finders separately from collection finders' do
    expect(described_class.names(:finder)).to contain_exactly(
      :find, :ancestor, :sibling, :find_button, :find_by_id,
      :find_field, :find_link
    )
    expect(described_class.names(:collection)).to contain_exactly(
      :all, :find_all, :first
    )
  end

  it 'combines query categories without duplicate methods' do
    names = described_class.names(:finder, :collection, :finder)

    expect(names.size).to eq(10)
    expect(names.uniq).to eq(names)
  end

  it 'classifies each public API family' do
    expected = {
      find: :finder, all: :collection, assert_css: :selector,
      matches_css?: :match, refute_content: :text, click_on: :action,
      must_have_all_of_selectors: :grouped
    }

    expected.each do |name, type|
      expect(described_class.type(name)).to eq(type)
    end
  end

  it 'distinguishes selector arguments from fixed selectors' do
    expected = {
      find: :selector, have_ancestor: :selector, have_sibling: :selector,
      have_any_of_selectors: :selector, find_button: :button,
      has_checked_field?: :field, has_unchecked_field?: :field,
      assert_css: :css, match_xpath: :xpath, have_text: nil
    }

    expected.each do |name, selector|
      expect(described_class.selector(name)).to eq(selector)
    end
  end

  it 'recognizes Minitest text aliases but not nonexistent element wrappers' do
    expect(described_class.names(:text)).to include(
      :assert_content, :assert_no_content, :refute_text, :refute_content,
      :must_have_text, :wont_have_text, :must_have_content, :wont_have_content
    )
    expect(described_class.names(:selector)).not_to include(
      :must_have_element, :wont_have_element
    )
  end

  it 'does not infer an API category from an unrelated method name' do
    expect(described_class.type(:have_custom)).to be_nil
    expect(described_class.selector(:have_custom)).to be_nil
  end

  it 'returns no methods for an unknown category' do
    expect(described_class.names(:unknown)).to be_empty
  end

  it 'distinguishes built-in selectors from custom and unknown selectors' do
    expect(described_class.built_in_selector?(:css)).to be(true)
    expect(%i[custom selector].map do |selector|
      described_class.built_in_selector?(selector)
    end).to eq([false, false])
  end
end
