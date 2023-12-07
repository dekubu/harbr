module Harbr
  class Pool # rubocop:disable Style/Documentation
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
