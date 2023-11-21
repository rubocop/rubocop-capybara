# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::CssSelector do
  describe 'CssSelector.id' do
    context 'when string whose argument begins with `#`' do
      it 'returns id string' do
        expect(described_class.id('#some-id')).to eq 'some-id'
        expect(described_class.id('#some-id.cls')).to eq 'some-id'
      end

      it 'returns id string when contain `\`' do
        expect(described_class.id('#some-id\.id')).to eq 'some-id\\.id'
      end
    end

    context 'when string whose argument not begins with `#`' do
      it 'returns nil' do
        expect(described_class.id('some-element')).to be_nil
        expect(described_class.id('.some-cls')).to be_nil
      end
    end
  end

  describe 'CssSelector.id?' do
    context 'when string whose argument begins with `#`' do
      it 'returns true' do
        expect(described_class.id?('#some-id')).to be true
        expect(described_class.id?('#some-id.cls')).to be true
      end
    end

    context 'when string whose argument not begins with `#`' do
      it 'returns false' do
        expect(described_class.id?('some-element')).to be false
        expect(described_class.id?('.some-cls')).to be false
      end
    end
  end

  describe 'CssSelector.classes' do
    context 'when string whose argument contains `.`' do
      it 'returns class name array when class string specified one' do
        expect(described_class.classes('.some-cls')).to match ['some-cls']
        expect(described_class.classes('h1#foo.bar')).to match ['bar']
      end

      it 'returns class name array when class string specified more than one' do
        expect(described_class.classes('.cls1.cls2')).to match %w[cls1 cls2]
        expect(described_class.classes('h2.cls1.cls2')).to match %w[cls1 cls2]
      end
    end

    context 'when string whose argument not contains `.`' do
      it 'returns empty array' do
        expect(described_class.classes('some-element')).to match []
        expect(described_class.classes('#some-id')).to match []
      end
    end
  end

  describe 'CssSelector.attribute?' do
    it 'returns true when string starting with `[`' do
      expect(described_class.attribute?('[attribute]')).to be true
    end

    it 'returns false when string not starting with `[`' do
      expect(described_class.attribute?('attribute')).to be false
    end
  end

  describe 'CssSelector.attributes' do
    it 'returns attributes hash when specify attributes' do
      expect(described_class.attributes('a[foo-bar_baz]')).to eq(
        'foo-bar_baz' => nil
      )
      expect(described_class.attributes('table[foo=bar]')).to eq(
        'foo' => "'bar'"
      )
    end

    it 'returns attributes hash when specify multiple attributes' do
      expect(described_class.attributes('button[foo][bar=baz]')).to eq(
        'foo' => nil, 'bar' => "'baz'"
      )
    end

    it 'returns attributes hash when specify nested attributes' do
      expect(described_class.attributes('[foo="bar[baz]"]')).to eq(
        'foo' => "'bar[baz]'"
      )
    end

    it 'returns attributes hash when specify nested and include ' \
       'multiple bracket' do
      expect(described_class.attributes('[foo="bar[baz][qux]"]')).to eq(
        'foo' => "'bar[baz][qux]'"
      )
    end

    it 'returns empty hash when specify not include attributes' do
      expect(described_class.attributes('h1.cls#id')).to eq({})
    end
  end

  describe 'CssSelector.pseudo_classes' do
    it 'returns pseudo class array when include pseudo classes' do
      expect(
        described_class.pseudo_classes('button:not([disabled])')
      ).to match ['not()']
      expect(
        described_class.pseudo_classes('a:enabled:not([valid])')
      ).to match ['enabled', 'not()']
    end

    it 'returns empty array when not include pseudo classes' do
      expect(described_class.pseudo_classes('button')).to match []
    end
  end

  describe 'CssSelector.multiple_selectors?' do
    it 'returns true when space-separated selectors' do
      expect(described_class.multiple_selectors?('a.cls b#id')).to be true
    end

    it 'returns true when selectors separated by `>`' do
      expect(described_class.multiple_selectors?('a.cls>b#id')).to be true
    end

    it 'returns true when selectors separated by `,`' do
      expect(described_class.multiple_selectors?('a.cls,b#id')).to be true
    end

    it 'returns true when selectors separated by `+`' do
      expect(described_class.multiple_selectors?('a.cls+b#id')).to be true
    end

    it 'returns true when selectors separated by `~`' do
      expect(described_class.multiple_selectors?('a.cls~b#id')).to be true
    end

    it 'returns false when single selector' do
      expect(described_class.multiple_selectors?('a.cls')).to be false
      expect(described_class.multiple_selectors?('a.cls\>b')).to be false
    end
  end
end
