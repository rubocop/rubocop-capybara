# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::UnorderedWindowAccess do
  it 'reports positional access on the result of Capybara windows' do
    expect_offense(<<~RUBY)
      windows.first
      ^^^^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
      windows.last
      ^^^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
      windows[1]
      ^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
      windows.at(0)
      ^^^^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
      windows.fetch(index)
      ^^^^^^^^^^^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
    RUBY

    expect_no_corrections
  end

  it 'recognizes explicit Capybara sessions' do
    expect_offense(<<~RUBY)
      page.windows.last
      ^^^^^^^^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
      page&.windows&.first
      ^^^^^^^^^^^^^^^^^^^^ Selecting a window by position relies on undefined order. Use `window_opened_by` or `current_window`.
    RUBY
  end

  it 'leaves order-independent access and other windows methods alone' do
    expect_no_offenses(<<~RUBY)
      windows.size
      windows.find(&:current?)
      windows.sort_by(&:handle).first
      windows[0..-1]
      windows[..-1]
      other.windows.last
      array.first
    RUBY
  end
end
