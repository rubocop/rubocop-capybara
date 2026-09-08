# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Capybara::ModalMethodWithoutBlock do
  it 'registers offenses for modal methods without a block' do
    expect_offense(<<~RUBY)
      accept_alert
      ^^^^^^^^^^^^ Call `accept_alert` with a block.
      accept_confirm
      ^^^^^^^^^^^^^^ Call `accept_confirm` with a block.
      accept_prompt(with: 'answer')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Call `accept_prompt` with a block.
      dismiss_confirm
      ^^^^^^^^^^^^^^^ Call `dismiss_confirm` with a block.
      dismiss_prompt
      ^^^^^^^^^^^^^^ Call `dismiss_prompt` with a block.
    RUBY
  end

  it 'registers offenses with a receiver or safe navigation' do
    expect_offense(<<~RUBY)
      page.accept_confirm
      ^^^^^^^^^^^^^^^^^^^ Call `accept_confirm` with a block.
      page&.dismiss_confirm
      ^^^^^^^^^^^^^^^^^^^^^ Call `dismiss_confirm` with a block.
    RUBY
  end

  it 'does not register an offense with a literal block' do
    expect_no_offenses(<<~RUBY)
      accept_confirm do
        click_button 'Delete'
      end
      page.dismiss_confirm { click_button 'Cancel' }
    RUBY
  end

  it 'does not register an offense with a block-pass argument' do
    expect_no_offenses(<<~RUBY)
      accept_prompt(with: 'answer', &trigger_modal)
    RUBY
  end

  it 'does not register an offense when forwarding arguments and a block' do
    expect_no_offenses(<<~RUBY)
      def trigger(...)
        page.accept_confirm(...)
        page&.dismiss_prompt('Answer', ...)
      end
    RUBY
  end

  it 'registers an offense when forwarding arguments without a block' do
    expect_offense(<<~RUBY)
      def trigger(*args, **options)
        accept_confirm(*args, **options)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Call `accept_confirm` with a block.
      end
    RUBY
  end

  it 'does not mistake an enclosing block for a block passed to the modal' do
    expect_offense(<<~RUBY)
      tap { accept_confirm }
            ^^^^^^^^^^^^^^ Call `accept_confirm` with a block.
    RUBY
  end

  context 'with anonymous block forwarding' do
    include_context 'ruby 3.1'

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def trigger(&)
          accept_confirm(&)
          page&.dismiss_prompt(with: 'answer', &)
        end
      RUBY
    end
  end

  it 'recognizes numbered block parameters' do
    expect_no_offenses(<<~RUBY)
      page&.accept_prompt { puts _1 }
    RUBY
  end
end
