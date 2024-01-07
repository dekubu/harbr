require "thor"
require "dddr"
require "terminal-table"
require "yaml"
require "toml-rb"
require "fileutils"
require "ostruct"
require "sucker_punch"
require "resend"

require_relative "harbr/version"
require_relative "harbr/container"
require_relative "harbr/job"
require_relative "harbr/lxd/job"
require_relative "harbr/lxd/setup"



# Harbr module for managing containers, jobs, ports, and 2s
module Harbr
  DEFAULT_DIRECTORY = "/var/harbr/containers"
  DEFAULT_DIRECTORY_DATA_DIR = "#{DEFAULT_DIRECTORY}/.data"

  Dddr.configure do |config|
    config.data_dir = DEFAULT_DIRECTORY_DATA_DIR
  end

  class Error < StandardError; end

  def self.send_notification(subject, body)
    resend_config = YAML.load_file("/etc/harbr/resend.yml")

    Resend.api_key = resend_config["key"]

    params = {
      from: resend_config["from"],
      to: resend_config["to"],
      subject: subject,
      html: body
    }

    puts "Sending notification: #{params}"

    Resend::Emails.send(params)
  rescue => e
    puts "Error: #{e.class}"
    puts "backtrace: #{e.backtrace.join('\n')}"
    puts "Error sending notification: #{e.message}"
  end

  def self.notifiable(name, version, env)
    yield if block_given?
    send_notification("Harbr: #{name} deployed to #{env} successfully", "<p>harbr: #{version} of #{name} deployed to #{env} successfully</p>")
  rescue => e
    html_content = <<~HTML
      <p>Error: #{e.message}</p>
                <p>#{e.backtrace.join("<br>")}</p>
                <p>harbr: #{version} of #{env} #{name} failed to deploy</p>
    HTML

    send_notification("Harbr: #{name} failed to deploy", html_content)
  end
end
