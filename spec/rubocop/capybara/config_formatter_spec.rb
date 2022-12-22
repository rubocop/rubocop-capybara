# frozen_string_literal: true

require 'rubocop/capybara/config_formatter'

RSpec.describe RuboCop::Capybara::ConfigFormatter do
  let(:config) do
    {
      'AllCops' => {
        'Setting' => 'forty two'
      },
      'Capybara/Foo' => {
        'Config' => 2,
        'Enabled' => true
      },
      'Capybara/Bar' => {
        'Enabled' => true,
        'Nullable' => nil
      },
      'Capybara/Baz' => {
        'Enabled' => true,
        'StyleGuide' => '#buzz'
      }
    }
  end

  let(:descriptions) do
    {
      'Capybara/Foo' => {
        'Description' => 'Blah'
      },
      'Capybara/Bar' => {
        'Description' => 'Wow'
      },
      'Capybara/Baz' => {
        'Description' => 'Woof'
      }
    }
  end

  it 'builds a YAML dump with spacing between cops' do
    formatter = described_class.new(config, descriptions)

    expect(formatter.dump).to eql(<<-YAML.gsub(/^\s+\|/, ''))
      |---
      |AllCops:
      |  Setting: forty two
      |
      |Capybara/Foo:
      |  Config: 2
      |  Enabled: true
      |  Description: Blah
      |  Reference: https://www.rubydoc.info/gems/rubocop-capybara/RuboCop/Cop/Capybara/Foo
      |
      |Capybara/Bar:
      |  Enabled: true
      |  Nullable: ~
      |  Description: Wow
      |  Reference: https://www.rubydoc.info/gems/rubocop-capybara/RuboCop/Cop/Capybara/Bar
      |
      |Capybara/Baz:
      |  Enabled: true
      |  StyleGuide: "#buzz"
      |  Description: Woof
      |  Reference: https://www.rubydoc.info/gems/rubocop-capybara/RuboCop/Cop/Capybara/Baz
    YAML
  end
end
