# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 99.12, branch: 89.90
  add_filter '/spec/'
  add_filter '/vendor/bundle/'
end
