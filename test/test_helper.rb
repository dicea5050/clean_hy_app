ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # NOTE: System tests create data explicitly in each test.
    # Auto-loading all fixtures can cause FK violations if some fixtures are incomplete.
    # Therefore, do NOT auto-load fixtures here.

    # Add more helper methods to be used by all tests here...
  end
end

# System test tuning
if defined?(Capybara)
  Capybara.default_max_wait_time = 5
end
