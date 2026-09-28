# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::AbsoluteXPathInElementScope do
  it 'reports document-root XPath searches on finder results' do
    expect_offense(<<~RUBY)
      find('.dialog').find(:xpath, '//button')
      #{' ' * 29}^^^^^^^^^^ Use `.//` for an XPath search within an element.
      page.find('.dialog').all(:xpath, '//button')
      #{' ' * 33}^^^^^^^^^^ Use `.//` for an XPath search within an element.
      dialog = page.find('.dialog')
      dialog.find(:xpath, '//button')
      #{' ' * 20}^^^^^^^^^^ Use `.//` for an XPath search within an element.
    RUBY

    expect_no_corrections
  end

  it 'leaves document-level, relative, and unknown-receiver queries alone' do
    expect_no_offenses(<<~RUBY)
      find(:xpath, '//button')
      page.find(:xpath, '//button')
      find('.dialog').find(:xpath, './/button')
      find('.dialog').find(:css, '//button')
      element.find(:xpath, '//button')
      Model.find('.dialog').find(:xpath, '//button')
      session = page
      session.find(:xpath, '//button')
      dialog = page.find('.dialog')
      dialog = page
      dialog.find(:xpath, '//button')
      find('.dialog').find(:xpath, expression)
      find('.dialog').find(:xpath, "//\#{kind}")
    RUBY
  end

  it 'recognizes elements defined by named RSpec helpers' do
    expect_offense(<<~RUBY)
      RSpec.describe 'dialog' do
        let(:dialog) { find('.dialog') }
        let!(:notice) { page.find('.notice') }
        subject(:panel) { find('.panel') }

        it 'searches inside elements' do
          dialog.find(:xpath, '//button')
          #{' ' * 20}^^^^^^^^^^ Use `.//` for an XPath search within an element.
          notice.find(:xpath, '//button')
          #{' ' * 20}^^^^^^^^^^ Use `.//` for an XPath search within an element.
          panel.find(:xpath, '//button')
          #{' ' * 19}^^^^^^^^^^ Use `.//` for an XPath search within an element.
        end
      end
    RUBY
  end

  it 'leaves unknown and overridden RSpec helpers alone' do
    expect_no_offenses(<<~RUBY)
      RSpec.describe 'no helper' do
        it { unknown.find(:xpath, '//button') }
      end

      RSpec.describe 'not a named helper' do
        include SomeModule
        subject { find('.dialog') }
        other.let(:dialog) { find('.dialog') }
        it { dialog.find(:xpath, '//button') }
      end

      RSpec.describe 'dialog' do
        let(:dialog) { find('.dialog') }
        let(:unknown) { Object.new }

        context 'overridden' do
          let(:dialog) { Object.new }

          it 'uses the local binding' do
            dialog.find(:xpath, '//button')
            unknown.find(:xpath, '//button')
          end
        end
      end
    RUBY
  end
end
