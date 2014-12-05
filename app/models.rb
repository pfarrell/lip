require 'sequel'
require 'logger'

$console = Logger.new STDOUT
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/lip',logger: $console)

DB.sql_log_level = :debug
Sequel::Model.plugin :timestamps

require 'models/room'
