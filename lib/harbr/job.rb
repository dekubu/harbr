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
      dirname = File.dirname(path)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

      File.write(path, contents)
    end

    def load_manifest(name, version)
      manifest_path = "/var/harbr/containers/#{name}/versions/#{version}/config/manifest.yml"
      check_file_exists(manifest_path)
      raise "Manifest not found at #{manifest_path}" unless File.exist?(manifest_path)

      manifest_data = YAML.load_file(manifest_path)
      OpenStruct.new(manifest_data)
    end

    def perform(name, version, env)
      Harbr.notifiable(name, version) do
        manifest = load_manifest(name, version)
        port = `port assign #{env}.#{manifest.port}`.strip
        process_container(name,version,port,env,manifest)
      end
    end

    private

    def check_file_exists(path)
      sleep_times = [1, 3, 5, 8, 23]
      begin
        sleep_times.each do |time|
          puts "checking #{path}...."
          if File.exist?(path)
            puts "found #{path}"
            return
          end
          sleep(time)
        end
        raise "Directory not found: #{path}"
      rescue => e
        puts "Error: #{e.message}"
      end
    end

    def check_dir_exists(path)
      sleep_times = [1, 3, 5, 8, 23]
      begin
        sleep_times.each do |time|
          puts "checking #{path}...."
          if Dir.exist?(path)
            puts "found #{path}"
            return
          end
          sleep(time)
        end
        raise "Directory not found: #{path}"
      rescue => e
        puts "Error: #{e.message}"
      end
    end

    def process_container(name, version, port, env, manifest)

      version_path = "/var/harbr/containers/#{name}/versions/#{version}"

      system "sv stop #{env}.#{name}" if env == "next"
      system "sv stop #{name}" if env == "current"

      bundle_install_if_needed(version_path)

      create_runit_scripts(name, port, env)
      link_directories(name, version, env)
      sync_live_data_if_next(name) if env == "next"

      containers = collate_containers("#{name}", "#{manifest.host}", port) if env == "current"
      containers = collate_containers("#{env}.#{name}", "#{env}.#{manifest.host}", port) if env == "next"

      create_traefik_config(containers)

      system "sv start #{env}.#{name}" if env == "next"
      system "sv start #{name}" if env == "current"
      


      puts "harbr: #{version} of #{name} in #{env} environment"
    end

    def bundle_install_if_needed(path)
      
      check_dir_exists(path)

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

      if env == "next"
        write_to_file "/etc/sv/harbr/#{name}/#{env}/run", run_script
        write_to_file "/etc/sv/harbr/#{name}/#{env}/log/run", log_script
        write_to_file "/etc/sv/harbr/#{name}/#{env}/log/run", finish_script
        `chmod +x /etc/sv/harbr/#{name}/#{env}/run`
        `chmod +x /etc/sv/harbr/#{name}/#{env}/finish`
        `chmod +x /etc/sv/harbr/#{name}/#{env}/log/run`
      end

      if env == "current"
        write_to_file "/etc/sv/harbr/#{name}/run", run_script
        write_to_file "/etc/sv/harbr/#{name}/log/run", log_script
        write_to_file "/etc/sv/harbr/#{name}/log/finish", finish_script
        `chmod +x /etc/sv/harbr/#{name}/run`
        `chmod +x /etc/sv/harbr/#{name}/finish`
        `chmod +x /etc/sv/harbr/#{name}/log/run`
      end

      
    end

    def link_directories(name, version, env)
      if env == "next"
      `rm -f /etc/service/#{env}.#{name}`
      `rm -f /var/harbr/containers/#{name}/#{env}`
      `ln -sf /var/harbr/containers/#{name}/versions/#{version} /var/harbr/containers/#{name}/#{env}`
      `ln -sf /etc/sv/harbr/#{name}/#{env} /etc/service/#{env}.#{name}`
      end

      if env == "current"
      
      `rm -f /etc/service/#{name}`
      `rm -f /var/harbr/containers/#{name}`

      `ln -sf /var/harbr/containers/#{name}/versions/#{version} /var/harbr/containers/#{name}/current`
      `ln -sf /etc/sv/harbr/#{name} /etc/service/#{name}`
      end
            
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
