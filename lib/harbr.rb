# frozen_string_literal: true
require_relative "harbr/version"
require 'dddr'

module Harbr
  class Error < StandardError; end
   class Container
    include Dddr::Entity
    attr_accessor :name, :host_header, :ip, :port  
   end

   # Your code goes here...
end
