# frozen_string_literal: true
require_relative "harbr/version"
require 'dddr'

module Harbr
  class Error < StandardError; end
   class Container
    include Dddr::Entity
    attr_accessor :name, :host_header, :ip, :port  
   end

   class Port
    
    include Dddr::Entity
    attr_accessor :host_header, :number

    queries do
      def has_port_number?(number)
        all.find {|port| port.number == number.to_i}
      end
    end
    class Pool
      def initialize(port_range=50000..51000)
        
        @ports = Port::Repository.new        
        
        port_range.each do |number|
          port = Port.new        
          port.number = number
          unless @ports.has_port_number? number
            @ports.add(port) 
            puts port.number.to_s + " added!"
          end

        end

      end
    
      def get_port(host_header)
        
      end
    
      def return_port(port)
        
      end
    
      def ports
        @ports.all
      end

    end


  end
  
   
   # Your code goes here...
end
