# frozen_string_literal: true

RSpec.configure do |config|
  SELENIUM_WINDOW_SIZE = [1920, 1280]
  Capybara.register_driver :local_selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new(
      args: [
        'headless'
      ]
    )

    Capybara::Selenium::Driver
      .new(app, browser: :chrome, options: options)
      .tap { |driver| driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*SELENIUM_WINDOW_SIZE) }
  end

  Capybara.register_driver :remote_selenium_chrome do |app|
    capabilities = Selenium::WebDriver::Remote::Capabilities.new(browser_name: :chrome, loggingPrefs: { browser: 'ALL' })

    Capybara::Selenium::Driver.new(
      app,
      **{ browser: :remote, url: ENV.fetch('SELENIUM_DRIVER_URL'), options: capabilities }
    ).tap { |driver| driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*SELENIUM_WINDOW_SIZE) }
  end

  Capybara.configure do |capybara_config|
    capybara_config.app_host = 'http://localhost'
    capybara_config.server_port = 3000
    capybara_config.default_driver = :selenium
    capybara_config.default_max_wait_time = 10
  end

  config.around(type: :system) do |example|
    WebMock.allow_net_connect!
    VCR.turned_off { example.run }
    WebMock.disable_net_connect!
  end

  config.before(type: :system) { driven_by :rack_test }

  config.before(type: :system, js: true) do
    if ENV['SELENIUM_DRIVER_URL'].present?
      driven_by :remote_selenium_chrome
    else
      driven_by :local_selenium_chrome_headless
    end
  end

  config.after(type: :system) { warn(page.driver.browser.manage.logs.get(:browser)) }
end
