require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Helper: Click submit within a specific form action to avoid header logout button
  def submit_within(action_path)
    within("form[action='#{action_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
  end

  # Helper: Click a delete link; if it has confirm (rails-ujs/turbo), accept it
  def click_delete_selector(selector)
    return unless page.has_selector?(selector, wait: 2)
    attempts = 0
    begin
      el = find(selector, match: :first)
      if el[:'data-confirm'] || el[:'data-turbo-confirm']
        begin
          accept_confirm { el.click }
        rescue Capybara::ModalNotFound
          # フォールバック：確認モーダルが実際には出ない場合
          el = find(selector, match: :first)
          el.click
        end
      else
        el.click
      end
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      attempts += 1
      retry if attempts < 2
      raise
    end
  end
end
