require "yaml"
require "ostruct"
require "sucker_punch"
require "harbr"
require "tomlrb"

module Harbr
  class Job
    include SuckerPunch::Job

    def get_container_name(path)
      File.basename(path)
    end

    def create_traefik_config(containers)
      config = {
        "http" => {
          "routers" => {},
          "services" => {}
        }
      }

      containers.each do |container|
        container.ip = "127.0.0.1"
        name = container.name.tr(".", "-")

        router_key = "#{name}-router-secure"
        config["http"]["routers"][router_key] = {
          "rule" => "Host(`#{container.host_header}`)",
          "service" => "#{name}-service",
          "entryPoints" => ["https"],
          "tls" => {
            "certResolver" => "myresolver"
          }
        }

        config["http"]["services"]["#{name}-service"] = {
          "loadBalancer" => {
            "servers" => [{"url" => "http://#{container.ip}:#{container.port}"}]
          }
        }
      end

      File.write("/etc/traefik/harbr.toml", TomlRB.dump(config))
      puts "Traefik configuration written to /etc/traefik/harbr.toml"
    end

    def collate_containers(name, host, port)
      containers = Harbr::Container::Repository.new
      container = containers.find_by_header(host)

      if container.nil?
        container = Harbr::Container.new
        container.name = name
        container.host_header = host
        container.ip = "127.0.0.1"
        container.port = port
        containers.create(container)
      else
        container.port = port
        containers.update(container)
      end

      containers.all
    end

    def write_to_file(path, contents)
      File.write(path, contents)
    end

    def load_manifest(container, version)
      manifest_path = "/var/harbr/containers/#{container}/versions/#{version}/config/manifest.yml"
      raise "Manifest not found at #{manifest_path}" unless File.exist?(manifest_path)

      manifest_data = YAML.load_file(manifest_path)
      OpenStruct.new(manifest_data)
    end

    def perform(name, version, env)
      Harbr.notifiable(name, version) do
        manifest = load_manifest(name, version)
        port = `port assign #{env}.#{manifest.port}`.strip

        current_path = "/var/harbr/containers/#{name}/versions/#{version}"
        check_dir_exists(current_path)

        process_container(name, version, port, env, manifest)
      end
    end

    private

    def check_dir_exists(path)
      sleep_times = [1, 3, 5, 8, 23]
      begin
        sleep_times.each do |time|
          return if Dir.exist?(path)
          sleep(time)
        end
        raise "Directory not found: #{path}"
      rescue => e
        puts "Error: #{e.message}"
      end
    end

    def process_container(name, version, port, env, manifest)
      env_path = "/var/harbr/containers/#{name}/#{env}"
      system "sv stop #{env}.#{name}" if env == 'next'

      bundle_install_if_needed(env_path)
      create_runit_scripts(name, port, env)
      link_directories(name, version, env)
      sync_live_data_if_next(name) if env == 'next'

      containers = collate_containers("#{env}.#{name}", "#{env}.#{manifest.host}", port)
      create_traefik_config(containers)
      puts "harbr: #{version} of #{name} in #{env} environment"
    end

    def bundle_install_if_needed(path)
      Dir.chdir(path) do
        if File.exist?("Gemfile")
          `bundle config set --local path 'vendor/bundle'`
          system "bundle install"
        end
      end
    end

    def create_runit_scripts(name, port, env)
      run_script = Runit::Script.new(name, port, env).run_script
      finish_script = Runit::Script.new(name, port, env).finish_script
      log_script = Runit::Script.new(name, port, env).log_script

      write_to_file "/etc/sv/harbr/#{name}/#{env}/run", run_script
      write_to_file "/etc/sv/harbr/#{name}/#{env}/finish", finish_script
      write_to_file "/etc/sv/harbr/#{name}/#{env}/log/run", log_script

      `chmod +x /etc/sv/harbr/#{name}/#{env}/run`
      `chmod +x /etc/sv/harbr/#{name}/#{env}/log/run`
      `chmod +x /etc/sv/harbr/#{name}/#{env}/finish`
    end

    def link_directories(name, version, env)
      `rm -f /etc/service/#{env}.#{name}`
      `rm -f /var/harbr/containers/#{name}/#{env}`

      `ln -sf /var/harbr/containers/#{name}/versions/#{version} /var/harbr/containers/#{name}/#{env}`
      `ln -sf /etc/sv/harbr/#{name}/#{env} /etc/service/#{env}.#{name}`
    end

    def sync_live_data_if_next(name)
      `rsync -av /var/dddr/#{name}/live /var/dddr/#{name}/next`
      puts "sync live data to next"
    end
  end

  module Runit
    class Script
      def initialize(container, port, env)
        @container_name = container
        @port = port
        @env = env
      end

      def run_script
        <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          cd /var/harbr/containers/#{@container_name}/#{@env}
          exec ./exe/run #{@port} #{@env}
        SCRIPT
      end

      def finish_script
        <<~SCRIPT
          #!/bin/sh
          sleep 3
          `lsof -i :#{@port} | awk 'NR!=1 {print $2}' | xargs kill`
        SCRIPT
      end

      def log_script
        <<~SCRIPT
          #!/bin/sh
          exec svlogd -tt /var/log/harbr/#{@container_name}/#{@env}/
        SCRIPT
      end
    end
  end
end
