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
  DEFAULT_DIRECTORY = "/var/harbr"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"
  class Error < StandardError; end

  def self.highest_numbered_directory(path)
    directories = Dir.glob("#{path}/*").select { |entry| File.directory?(entry) }
    directories.max_by { |entry| entry[/\d+/].to_i }
  end

  module Runit
    class Run
      def initialize(container, port)
        @container_name = container
        @port = port
      end

      def to_s
        script_template = <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          cd /var/harbr/#{@container_name}/current
          exec ./exe/run #{@port}
        SCRIPT
      end

      def link
        "ln -s /etc/sv/harbr/#{@container_name} /etc/service/#{@container_name}"
      end
    end

    class Log
      def initialize(container, port)
        @container_name = container
      end

      def to_s
        script_template = <<~SCRIPT
          #!/bin/sh
          exec svlogd -tt /var/log/harbr/#{@container_name}/next/
        SCRIPT
      end

      def link
        "ln -s /etc/sv/harbr/#{@container_name}/log /etc/service/#{@container_name}/log"
      end
    end

    module Next
      class Run
        def initialize(container, port)
          @container_name = container
          @port = port
        end

        def to_s
          script_template = <<~SCRIPT
            #!/bin/sh
            exec 2>&1
            cd /var/harbr/#{@container_name}/next
            exec ./exe/run #{@port}
          SCRIPT
        end

        def link
          "ln -s /etc/sv/harbr/#{@container_name}/next /etc/service/next.#{@container_name}"
        end
      end
      class Log
        def initialize(container, port)
          @container_name = container
        end
  
        def to_s
          script_template = <<~SCRIPT
            #!/bin/sh
            exec svlogd -tt /var/log/harbr/#{@container_name}/next/
          SCRIPT
        end
  
        def link

          "ln -s /etc/sv/harbr/#{container_name}/next/log/ /etc/service/next.#{container_name}/log"
        end
      end
  
    end
  end
end

Dddr.configure do |config|
  config.data_dir = Harbr::DEFAULT_DIRECTORY_DATA_DIR
end
