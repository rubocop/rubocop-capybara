# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'rubocop/capybara/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-capybara'
  spec.summary = 'Code style checking for Capybara test files'
  spec.description = <<-DESCRIPTION
    Code style checking for Capybara test files (RSpec, Cucumber, Minitest).
    A plugin for the RuboCop code style enforcing & linting tool.
  DESCRIPTION
  spec.homepage = 'https://github.com/rubocop/rubocop-capybara'
  spec.authors = ['Yudai Takada']
  spec.licenses = ['MIT']

  spec.version = RuboCop::Capybara::Version::STRING
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.6.0'

  spec.require_paths = ['lib']
  spec.files = Dir[
    'lib/**/*',
    'config/*',
    '*.md'
  ]
  spec.extra_rdoc_files = ['MIT-LICENSE.md', 'README.md']

  spec.metadata = {
    'changelog_uri' => 'https://github.com/rubocop/rubocop-capybara/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://docs.rubocop.org/rubocop-capybara/',
    'rubygems_mfa_required' => 'true'
  }

  spec.add_runtime_dependency 'rubocop', '~> 1.41'
end
