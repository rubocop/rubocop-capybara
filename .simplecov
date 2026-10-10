# frozen_string_literal: true

SimpleCov.configure do
  enable_coverage :branch
  minimum_coverage line: 99.54, branch: 95.45
  skip ['/spec/', '/vendor/bundle/']
end
