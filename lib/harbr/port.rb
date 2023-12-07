# frozen_string_literal: true

module Harbr
  class Port # rubocop:disable Style/Documentation
    include Dddr::Entity
    attr_accessor :host_header, :number

    queries do
      # Checks if a port with the specified number exists.
      #
      # Parameters:
      # - number: The port number to check.
      #
      # Returns:
      # - The port object if found, nil otherwise.
      def has_port_number?(number)
        all.find { |port| port.number == number.to_i }
      end

      def assigned_a_port?(host_header)
        all.find { |port| port.host_header == host_header }
      end
    end
  end
end
