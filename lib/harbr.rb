# frozen_string_literal: true

require_relative "harbr/version"
require "dddr"
require "sucker_punch"
require "fileutils"

module Harbr
  
  DEFAULT_DIRECTORY = "/var/harbr"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"

  Dddr.configure do |config|
    config.data_dir = DEFAULT_DIRECTORY_DATA_DIR
  end



  class Error < StandardError; end

  class Container
    class Job
      include SuckerPunch::Job

      def perform(manifest)
        
        puts "Starting container: #{manifest.name}"

        Dddr.configure do |config|
          config.data_dir = Harbr::DEFAULT_DIRECTORY_DATA_DIR
        end

        pool = Harbr::Port::Pool.new
        port = pool.get_port(manifest.host)
      
        create_a_service(container_name, port)

        system("sv restart #{manifest.name}")
        system("sv status #{manifest.name}")
      
      end


      def create_run_script(container_name, port)
        service_dir = "/etc/sv/harbr/#{container_name}"
        if File.directory?(service_dir)
          puts "Directory already exists: #{service_dir}"
          return
        end
  
        script_template = <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          cd /var/harbr/#{container_name}/current
          exec bundle exec puma -p #{port}
        SCRIPT
  
        service_dir = "/etc/sv/harbr/#{container_name}"
        FileUtils.mkdir_p(service_dir)
        
        File.write("#{service_dir}/run", script_template)
        FileUtils.chmod("+x", "#{service_dir}/run")
        puts "Run script created and made executable for container: #{container_name}"
      end
  
      def create_log_script(container_name)
        log_dir = "/var/log/harbr/#{container_name}"
        if File.directory?(log_dir)
          puts "Directory already exists: #{log_dir}"
          return
        end
  
        script_template = <<~SCRIPT
          #!/bin/sh
          exec svlogd -tt #{log_dir}/
        SCRIPT
  
        dir_path = "/etc/sv/harbr/#{container_name}"
        FileUtils.mkdir_p(dir_path)
        
        File.write("#{dir_path}/run", script_template)
        FileUtils.chmod("+x", "#{dir_path}/run")
        puts "Log script created and made executable for container: #{container_name}"
      end
      
      def create_a_service(container_name, port)
        create_run_script(container_name, port)
        create_log_script(container_name)
        system("ln -s /etc/sv/harbr/#{container_name} /etc/service/#{container_name}") unless File.exist?("/etc/service/#{container_name}")
      end


    end

    include Dddr::Entity
    attr_accessor :name, :host_header, :ip, :port
  end

  class Port
    include Dddr::Entity
    attr_accessor :host_header, :number

    queries do
      def has_port_number?(number)
        all.find { |port| port.number == number.to_i }
      end

      def assigned_a_port?(host_header)
        all.find { |port| port.host_header == host_header }
      end
    end
    class Pool
      def initialize(port_range = 50000..51000)
        @repository = Port::Repository.new

        port_range.each do |number|
          port = Port.new
          port.number = number

          unless @repository.has_port_number? number
            @repository.add(port)
            puts port.number.to_s + " added!"
          end
        end
      end

      def get_port(host_header)
        port = @repository.assigned_a_port?(host_header)
        return port unless port.nil?

        port = ports.shuffle.sample
        port.host_header = host_header
        @repository.update(port)
        port
      end

      def return_port(port)
        port.host_header = nil
        @repository.update(port)
        port.host_header.nil?
      end

      def ports
        @repository.all
      end
    end
  end

  # Your code goes here...
end
