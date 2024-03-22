# frozen_string_literal: true

module RuboCop
  # RuboCop Capybara project namespace
  module Capybara
    PROJECT_ROOT = Pathname.new(__dir__).parent.parent.expand_path.freeze
    private_constant(:PROJECT_ROOT)
    ::RuboCop::ConfigObsoletion.files <<
      PROJECT_ROOT.join('config', 'obsoletion.yml')
  end
end
