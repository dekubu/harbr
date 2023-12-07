module Harbr
  class Container
    include Dddr::Entity
    attr_accessor :name, :host_header, :ip, :port

    queries do
      def find_by_header(host_header)
        all.find { |container| container.host_header.downcase == host_header.downcase }
      end
    end


  end
end
