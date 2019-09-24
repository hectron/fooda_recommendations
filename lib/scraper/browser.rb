require 'forwardable'

module Scraper
  class Browser
    extend Forwardable

    def_delegator :client, :goto, :get
    def_delegators :client, :at_css, :css, :at_xpath, :xpath, :screenshot, :current_url

    DEFAULT_TIMEOUT       = 10 # seconds
    DEFAULT_WAIT_INTERVAL = 2 # seconds

    def initialize(opts = {})
      @client        = Ferrum::Browser.new(browser_options: { 'no-sandbox' => nil })
      @timeout       = opts.fetch(:timeout, DEFAULT_TIMEOUT)
      @wait_interval = opts.fetch(:wait_interval, DEFAULT_WAIT_INTERVAL)
      @options       = opts
    end

    def base_uri
      uri = URI.parse(client.current_url)

      "#{uri.scheme}://#{uri.host}"
    end

    def with_wait
      result = yield

      # Wait for the page to load
      timeout.times do
        if client.network.status == 200
          if client.evaluate('document.readyState') == 'complete'
            break
          else
            Rails.logger.debug('Waiting for the DOM document to be ready')
          end
        end

        sleep(wait_interval)
      end

      result
    end

    private

    attr_reader :client, :timeout, :wait_interval, :options
  end
end