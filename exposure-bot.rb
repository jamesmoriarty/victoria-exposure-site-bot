#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'sqlite3', '~> 1.4'
end

require 'logger'
require 'open-uri'
require 'csv'

class ExposureBot
  def initialize(logger: Logger.new(STDOUT, level: :info), db:)
    @logger = logger
    @db = db
  end

  def start
    logger.info("Starting")

    loop do
      begin
        csv = fetch_csv(CSV_URL)
        update_db(db, csv)
        notify_slack(db)

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

  CSV_URL = "https://docs.google.com/spreadsheets/d/e/2PACX-1vSNouXrJ8UQ-tn6bAxzrOdLINuoOtn01fSjooql0O3XQlj4_ldFiglzOmDm--t2jy1k-ABK6LMzPScs/pub?gid=1075463302&single=true&output=csv"

  def fetch_csv(url)
    logger.info("Fetching: #{CSV_URL}")
    io = URI.open(CSV_URL)

    CSV.parse(io.read, headers: true)
  end

  def update_db(db, csv)
    logger.info("Updating")
    count_updated, count_errored = 0, 0

    csv.each do |row|
      begin
        logger.debug(row)
        db.execute("INSERT INTO sites VALUES ( NULL, ?, ?, ?, ? )", [row['Exposure_date'], row['Exposure_time'], row['Site_streetaddress'], row['Site_postcode'].to_i])
        count_updated += 1
      rescue Exception => e
        count_errored += 1
      end
    end
    logger.info("Updated: #{count_updated} Errored: #{count_errored}")
  end

  def notify_slack(db)
    db.execute("SELECT * FROM sites").each do |row|

    end
  end

  attr_reader :logger, :db
end

db = SQLite3::Database.new(':memory:')

db.execute <<~SQL
  CREATE TABLE sites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date VARCHAR(30) NOT NULL,
    time VARCHAR(30) NOT NULL,
    address VARCHAR(30),
    postcode INT NOT NULL,
    UNIQUE(date, time, address, postcode) ON CONFLICT REPLACE
  );
SQL

db.execute <<~SQL
  CREATE TABLE slack_notifications (
    id integer PRIMARY KEY AUTOINCREMENT,
    site_id INTEGER NOT NULL,
    FOREIGN KEY(site_id) REFERENCES sites(id)
  );
SQL

ExposureBot.new(db: db).start
