# frozen_string_literal: true

require "dddr"
require "sucker_punch"
require "toml-rb"

require_relative "harbr/version"
require_relative "harbr/container"
require_relative "harbr/job"
require_relative "harbr/port"
require_relative "harbr/pool"

module Harbr # rubocop:disable Style/Documentation
  DEFAULT_DIRECTORY = "/var/harbr"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"

  Dddr.configure do |config|
    config.data_dir = DEFAULT_DIRECTORY_DATA_DIR
  end

  class Error < StandardError; end

  # Your code goes here...
end
