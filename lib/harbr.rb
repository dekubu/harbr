require "thor"
require "dddr"
require "terminal-table"
require "yaml"
require "toml-rb"
require "fileutils"
require "ostruct"
require "sucker_punch"

require_relative "harbr/version"
require_relative "harbr/container"
require_relative "harbr/job"
require_relative "harbr/next/job"

# Harbr module for managing containers, jobs, ports, and 2s
module Harbr
  DEFAULT_DIRECTORY = "/var/harbr/containers"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"
  class Error < StandardError; end

  def self.highest_numbered_directory(path)
    directories = Dir.glob("#{path}/*").select { |entry| File.directory?(entry) }
    directories.max_by { |entry| entry[/\d+/].to_i }
  end
  
end

Dddr.configure do |config|
  config.data_dir = Harbr::DEFAULT_DIRECTORY_DATA_DIR
end
