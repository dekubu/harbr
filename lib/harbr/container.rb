module Harbr
  class Container
    include Dddr::Entity
    attr_accessor :name, :host_header, :ip, :port

    queries do
      def find_by_header(host_header)
        all.find { |container| container.host_header.downcase == host_header.downcase }
      end

      def find_by_name(name)
        all.find { |container| container.name.downcase == name.downcase }
      end
      def get_by_name(name)
        all.select { |container| container.name.downcase.include? name.downcase }
      end
    end
  end
end
