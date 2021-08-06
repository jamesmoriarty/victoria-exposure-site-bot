require 'json'
require 'erb'
require 'open-uri'

require_relative '../models/site'

module ExposureBot
  module Service
    TEMPLATE = <<~ERB
      :medical_symbol: *<%= title %>* (#<%= id %>)

      <%= advice %>

      <% if postcode != 0 %>*Address*: <%= [address, postcode].compact.join(' ') %>
      <% end %>
      *Time*: <%= time %>
    ERB

    class NotifySlack
      def self.call(logger, db, sites, slack_url)
        logger.info("Notifying")

        create_table(logger, db)

        sites.each do |site|
          next if notified?(logger, db, site)

          notify(logger, db, site, slack_url)
        end
      end

      private

      def self.create_table(logger, db)
        db.execute <<~SQL
          CREATE TABLE slack_notifications (
            id integer PRIMARY KEY AUTOINCREMENT,
            site_id INTEGER NOT NULL,
            FOREIGN KEY(site_id) REFERENCES sites(id)
          );
        SQL
      rescue SQLite3::Exception => e
        logger.warn "DB: #{e.message}"
      end

      def self.notify(logger, db, site, slack_url)
        begin
          payload = {
            text: ERB.new(TEMPLATE)
                     .result_with_hash(
                       id: site.id,
                       title: site.title,
                       advice: site.advice,
                       address: site.address,
                       postcode: site.postcode,
                       time: [site.date, site.time].compact.join(' ')
                     )
          }

          headers = {
            'Content-Type' => 'application/json'
          }

          slack_uri = URI(slack_url)

          http = Net::HTTP.new(slack_uri.host, slack_uri.port)
          http.use_ssl = true if slack_uri.scheme == 'https'
          response = http.post(slack_uri.path, payload.to_json, headers)

          logger.info "Status: #{response.code} Body: #{response.body}"
        rescue => e
          logger.error("Error: #{e.message}")
        ensure
          db.execute("INSERT INTO slack_notifications VALUES ( NULL, ? )", [site.id])
        end
      end

      def self.notified?(logger, db, site)
        rows = db.execute("SELECT * FROM slack_notifications WHERE site_id = ?;", [site.id])

        !rows.empty?
      end
    end
  end
end
