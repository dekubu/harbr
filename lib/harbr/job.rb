module Harbr
  class Container
    class Job
      include SuckerPunch::Job
      def create_traefik_config(containers)
        config = {
          "http" => {
            "routers" => {
              "traefik-dashboard" => {
                "rule" => "Host(`traefik.harbr.zero2one.ee`)",
                "service" => "api@internal"
              }
            },
            "services" => {}
          }
        }

        containers.each do |container|
          container.ip = "127.0.0.1"

          config["http"]["routers"]["#{container.name}-router"] = {
            "rule" => "Host(`#{container.host_header}`)",
            "service" => "#{container.name}-service"
          }
          config["http"]["services"]["#{container.name}-service"] = {
            "loadBalancer" => {
              "servers" => [{"url" => "http://#{container.ip}:#{container.port}"}]
            }
          }
        end

        File.write("/etc/traefik/harbr.toml", TomlRB.dump(config))
        puts "Traefik configuration written to /etc/traefik/harbr.toml"
      end

      def create_run_script(container_name, port)
        service_dir = "/etc/sv/harbr/#{container_name}"
        if File.directory?(service_dir)
          puts "Directory already exists: #{service_dir}"
          return
        end

        script_template = <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          exec cd /var/harbr/#{container_name}/current
          exec bundle exec puma -p #{port}
        SCRIPT

        service_dir = "/etc/sv/harbr/#{container_name}"
        FileUtils.mkdir_p(service_dir)

        File.write("#{service_dir}/run", script_template)
        FileUtils.chmod("+x", "#{service_dir}/run")
        puts "Run script created and made executable for container: #{container_name}"
      end

      def create_log_script(container_name)
        log_dir = "/var/log/harbr/#{container_name}"

        if File.directory?(log_dir)
          puts "Directory already exists: #{log_dir}"
          return
        end

        FileUtils.mkdir_p(log_dir)

        script_template = <<~SCRIPT
          #!/bin/sh
          exec svlogd -tt #{log_dir}/
        SCRIPT

        dir_path = "/etc/sv/harbr/#{container_name}/log"
        FileUtils.mkdir_p(dir_path)

        File.write("#{dir_path}/run", script_template)
        FileUtils.chmod("+x", "#{dir_path}/run")
        puts "Log script created and made executable for container: #{container_name}"
      end

      def create_a_service(container_name, port)
        create_run_script(container_name, port)
        create_log_script(container_name)
        system("ln -s /etc/sv/harbr/#{container_name} /etc/service/#{container_name}") unless File.exist?("/etc/service/#{container_name}")
      end

      def run_container(manifest)
        puts "Starting container: #{manifest.name}"

        Dddr.configure do |config|
          config.data_dir = Harbr::DEFAULT_DIRECTORY_DATA_DIR
        end

        pool = Harbr::Port::Pool.new
        port = pool.get_port(manifest.host)

        create_a_service(manifest.name, port.number)

        container = Container.new
        containers = Container::Repository.new

        container.name = manifest.name
        container.host_header = manifest.host
        container.ip = manifest.ip.nil?
        container.port = port.number
        containers.add(container) unless containers.find_by_header(manifest.host)        
        system("cd /var/harbr/#{manifest.name}/current && bundle install")
        system("sv restart #{manifest.name}")
        puts "Started container: #{manifest.name}"
        create_traefik_config(containers.all)
      end

      def perform(manifest)
        `sv stop #{manifest.name}`
        `rm -rf /etc/sv/harbr/#{manifest.name}/`
        `rm -rf /etc/service/#{manifest.name}`
        `rm -rf /var/log/harbr/#{manifest.name}/`
        run_container(manifest)
      end
    end
  end
end
