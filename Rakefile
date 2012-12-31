require 'rake'
require 'erb'
require 'delayed/tasks'

ENV['RACK_ENV'] ||= 'development'
pwd = File.expand_path('..', __FILE__)

task :default => :help

desc 'List tasks (rake -T)'
task :help do
  sh 'rake -T'
end

desc 'Run example behaviors (specs)'
task :spec do
  sh 'rspec spec'
end

# Setup the environment for the application
task :environment do
  require 'delayed_job_active_record'
  require 'active_record'
  require 'pg'
  require 'logger'
  require 'erb'

  dbconfig = YAML.load(ERB.new(File.read('config/database.yml')).result)
  ActiveRecord::Base.establish_connection dbconfig[ENV['RACK_ENV']]
end

# Delayed Job database
namespace :db do
  desc "Create the database"
  task(:create) do
    require 'active_record'
    require 'pg'
    require 'yaml'

    dbconfig = YAML.load(ERB.new(File.read('config/database.yml')).result)
    ar_dbconfig = dbconfig[ENV['RACK_ENV']]
    ar_dbconfig_sys = ar_dbconfig.merge(
      'database' => 'postgres',
      'schema_search_path' => 'public',
    )
    # drops and create need to be performed with a connection to the 'postgres'
    # (system) database
    ActiveRecord::Base.establish_connection ar_dbconfig_sys
    # drop the old database (if it exists)
    ActiveRecord::Base.connection.drop_database ar_dbconfig['database']
    # Create the database
    ActiveRecord::Base.connection.create_database ar_dbconfig['database']
    puts "Created empty database #{ar_dbconfig['database']}"
  end

  desc "Migrate the database"
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

namespace :api do
  desc "Run the server using foreman form the Heroku toolbelt"
  task :run do
    sh 'foreman start'
  end

  desc "Submit a fake pull request"
  task(:pull_request) do
    sh 'curl -i --data "payload=$(cat spec/unit/fixtures/example_pull_request.json)" http://localhost:5000/event/pull_request'
  end
end