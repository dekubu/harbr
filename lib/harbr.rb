require "thor"
require "dddr"
require "harbr"
require "terminal-table"
require "yaml"
require "toml-rb"
require "fileutils"
require "ostruct"
require "sucker_punch"

require_relative "harbr/version"
require_relative "harbr/container"
require_relative "harbr/job"
require_relative "harbr/port"
require_relative "harbr/pool"

# Harbr module for managing containers, jobs, ports, and pools
module Harbr
  DEFAULT_DIRECTORY = "/var/harbr"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"

  Dddr.configure do |config|
    config.data_dir = DEFAULT_DIRECTORY_DATA_DIR
  end

  class Error < StandardError; end
end
