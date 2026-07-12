# frozen_string_literal: true

RSpec.describe 'cop lazy loading' do
  def run_script(source)
    Dir.mktmpdir do |dir|
      script = File.join(dir, 'script.rb')
      File.write(script, source)
      lib = File.expand_path('../../lib', __dir__)
      output = `#{RbConfig.ruby} -I #{lib} #{script} 2>&1`
      raise "script failed:\n#{output}" unless $CHILD_STATUS.success?

      output
    end
  end

  it 'registers every cop file in both departments exactly once' do
    cop_root = File.expand_path('../../lib/rubocop/cop', __dir__)
    files = Dir[File.join(cop_root, 'capybara', '{,rspec/}*.rb')].sort
    files -= [File.join(cop_root, 'capybara', 'rspec.rb')]

    registered = %w[Capybara Capybara/RSpec].flat_map do |department|
      cops = RuboCop::Cop::Registry.global.cops_for_department(department.to_sym)
      cops.map { |cop| Object.const_source_location(cop.name).first }
    end

    expect(registered.sort).to eq(files)
  end

  it 'registers all cops without loading their files' do
    output = run_script(<<~RUBY)
      require 'rubocop-capybara'

      registry = RuboCop::Cop::Registry.global
      loaded = $LOADED_FEATURES.grep(%r{/rubocop/cop/capybara/(?!mixin/)(?!rspec\\.rb)})

      puts "registered=\#{registry.names.grep(%r{\\ACapybara/}).size}"
      puts "loaded_cop_files=\#{loaded.size}"
    RUBY

    expect(output).to include('registered=15', 'loaded_cop_files=0')
  end

  it 'does not register a cop twice when its file is required directly' do
    output = run_script(<<~RUBY)
      require 'rubocop-capybara'

      before = RuboCop::Cop::Registry.global.length
      require 'rubocop/cop/capybara/rspec/current_path_expectation'
      after = RuboCop::Cop::Registry.global.length

      puts "stable=\#{before == after}"
      puts "class=\#{RuboCop::Cop::Registry.global.find_by_cop_name('Capybara/RSpec/CurrentPathExpectation')}"
    RUBY

    expect(output).to include('stable=true', 'class=RuboCop::Cop::Capybara::RSpec::CurrentPathExpectation')
  end
end
