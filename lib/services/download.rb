require 'csv'
require 'open-uri'

require_relative '../models/site'

module ExposureBot
  module Service
    class Download
      def self.call(logger, csv_url)
        logger.info("Fetching: #{csv_url}")
        io = URI.open(csv_url)

        CSV.parse(io.read, headers: true).map do |row|
          Site.new(
            nil,
            row['Exposure_date'],
            row['Exposure_time'],
            row['Site_streetaddress'],
            row['Site_postcode'].to_i,
            row['Site_title'].strip,
            row['Advice_title']
          )
        end
      end
    end
  end
end
