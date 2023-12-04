# frozen_string_literal: true

require_relative "harbr/version"
require "dddr"
require "sucker_punch"

module Harbr
  class Error < StandardError; end

  class Container
    class Job
      include SuckerPunch::Job

      def perform(manifest)
        puts "Harbr Job!"
        puts manifest
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
