# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::CssAttributesParser do
  describe 'CssSelector.new.parse' do
    it 'returns attributes hash when specify attributes' do
      expect(described_class.new('a[foo-bar_baz]').parse).to eq(
        'foo-bar_baz' => nil
      )
      expect(described_class.new('table[foo=bar]').parse).to eq(
        'foo' => "'bar'"
      )
    end

    it 'returns attributes hash when specify multiple attributes' do
      expect(described_class.new('button[foo][bar=baz]').parse).to eq(
        'foo' => nil, 'bar' => "'baz'"
      )
    end

    it 'returns attributes hash when specify nested attributes' do
      expect(described_class.new('[foo="bar[baz]"]').parse).to eq(
        'foo' => "'bar[baz]'"
      )
    end

    it 'returns attributes hash when specify nested and include ' \
       'multiple bracket' do
      expect(described_class.new('[foo="bar[baz][qux]"]').parse).to eq(
        'foo' => "'bar[baz][qux]'"
      )
    end

    it 'returns empty hash when specify not include attributes' do
      expect(described_class.new('h1.cls#id').parse).to eq({})
    end
  end
end
