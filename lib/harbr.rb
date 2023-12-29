require "thor"
require "dddr"
require "terminal-table"
require "yaml"
require "toml-rb"
require "fileutils"
require "ostruct"
require "sucker_punch"
require 'resend'

require_relative "harbr/version"
require_relative "harbr/container"
require_relative "harbr/job"
require_relative "harbr/next/job"

# Harbr module for managing containers, jobs, ports, and 2s
module Harbr
  DEFAULT_DIRECTORY = "/var/harbr/containers"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"
  class Error < StandardError; end

  def self.notifiable(name,version)
    begin
      yield if block_given?
      send_notification("Harbr: #{name} deployed successfully","<p>harbr: #{version} of #{name} deployed successfully</p>")
    rescue => e
      html_content = "<p>Error: #{e.message}</p>
              <p>#{e.backtrace.join('<br>')}</p>
              <p>harbr: #{version} of #{name} failed to deploy</p>"
      Harbr.send_notification("Harbr: #{name} failed to deploy",html_content)
    end
  end

  def self.send_notification(subject, body)
    begin
      Resend.api_key = ENV['RESEND_API_KEY']
      params = {
        from: ENV['RESEND_FROM'],
        to: ENV['RESEND_TO'],
        subject: subject,
        html: body
      }
      
      Resend::Emails.send(params)
    rescue => e
      puts "Error sending notification: #{e.message}"
      return
    end
    
  end

end

Dddr.configure do |config|
  config.data_dir = Harbr::DEFAULT_DIRECTORY_DATA_DIR
end
