require 'logger'

require_relative '../lib/services/download'
require_relative '../lib/services/save'
require_relative '../lib/services/notify_slack'

module ExposureBot
  class Process
    def initialize(logger: Logger.new(STDOUT, level: :info), csv_url:, slack_url:, db:)
      @csv_url = csv_url
      @slack_url = slack_url
      @logger = logger
      @db = db
    end

    def start
      logger.info("Starting")

      loop do
        begin
          sites = Service::Download.call(logger, csv_url)
          sites = Service::Save.call(logger, db, sites)
          Service::NotifySlack.call(logger, db, sites, slack_url)

          sleep 60
        rescue Interrupt
          logger.info("Exiting")
          exit(0)
        rescue Exception => e
          logger.error("Error: #{e.message}")
          logger.debug(e.backtrace.join("\n"))
        end
      end
    end

    private

    attr_reader :csv_url, :slack_url, :logger, :db
  end
end