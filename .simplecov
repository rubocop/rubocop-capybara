# frozen_string_literal: true

SimpleCov.configure do
  enable_coverage :branch
  coverage :line, minimum: 99.85
  coverage :branch, minimum: 97.84, ignore: :implicit_else
  skip ['/spec/', '/vendor/bundle/']
end
