require_relative '../models/site'

module ExposureBot
  module Service
    class Save
      def self.call(logger, db, sites)
        logger.info("Updating: #{sites.size}")

        create_table(logger, db)

        count_created, count_errored, ids = 0, 0, []

        sites.each do |site|
          begin
            row = db.execute("INSERT INTO sites VALUES ( NULL, ?, ?, ?, ?, ?, ? )",
                             [
                               site.date,
                               site.time,
                               site.address,
                               site.postcode,
                               site.title,
                               site.advice
                             ])

            if row.empty?
              count_errored += 1

              logger.debug(site)
              next
            end

            ids << row[0][0]
            count_created += 1
          rescue Exception => e
            logger.error("Error: #{e.message}")

            count_errored += 1
          end
        end
        logger.info("Created: #{count_created} Upserted/Errored: #{count_errored}")

        db.execute("SELECT * FROM sites").map { |row| Site.new(*row) }
      end

      private

      def self.create_table(logger, db)
        db.execute <<~SQL
          CREATE TABLE sites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date VARCHAR(30) NOT NULL,
            time VARCHAR(30) NOT NULL,
            address VARCHAR(255),
            postcode INT NOT NULL,
            title VARCHAR(255),
            advice VARCHAR(255) NOT NULL,
            UNIQUE(date, time, title, postcode, advice) ON CONFLICT IGNORE
          );
        SQL
      rescue SQLite3::Exception => e
        logger.warn "DB: #{e.message}"
      end
    end
  end
end
