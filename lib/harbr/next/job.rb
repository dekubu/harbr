module Harbr
  module Next
    class Job
      include SuckerPunch::Job
  
      def load_manifest(container,version)
        manifest_path = "/var/harbr/#{container}/versions/#{version}/config/manifest.yml"
        raise "Manifest not found at #{manifest_path}" unless File.exist?(manifest_path)
        manifest_data = YAML.load_file(manifest_path)
        OpenStruct.new(manifest_data)
      end
  
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

        service_dir = "/etc/sv/harbr/#{container_name}/next"
        
        script_template = <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          cd /var/harbr/#{container_name}/next
          exec ./exe/run #{port}
        SCRIPT
  
        service_dir = "/etc/sv/harbr/#{container_name}/next"
        FileUtils.mkdir_p(service_dir)
  
        File.write("#{service_dir}/run", script_template)
        FileUtils.chmod("+x", "#{service_dir}/run")
        puts "Run script created and made executable for container: next.#{container_name}"
      end
  
      def create_log_script(container_name)
        log_dir = "/var/log/harbr/#{container_name}/next"
  
        FileUtils.mkdir_p(log_dir)
  
        script_template = <<~SCRIPT
          #!/bin/sh
          exec svlogd -tt #{log_dir}/
        SCRIPT
  
        dir_path = "/etc/sv/harbr/#{container_name}/next/log"
        FileUtils.mkdir_p(dir_path)
  
        File.write("#{dir_path}/run", script_template)
        FileUtils.chmod("+x", "#{dir_path}/run")
        puts "Log script created and made executable for container: next.#{container_name}"
      end
  
      def create_a_service(container_name, port)
        create_run_script(container_name, port)
        create_log_script(container_name)
        system("ln -s /etc/sv/harbr/#{container_name}/next /etc/service/next.#{container_name}") unless File.exist?("/etc/service/next.#{container_name}")
      end
  
      def run_container(manifest)
        puts "Starting container: next.#{manifest.name}"
        port = `port assign next.#{manifest.port}`.strip

        create_a_service(manifest.name, port)
        
        containers = Container::Repository.new
        container = containers.find_by_header("next.#{manifest.host}")
  
        if container.nil?
          container = Container.new 
          container.name = "next.#{manifest.name}"
          container.host_header = "next.#{manifest.host}"
          container.ip = "127.0.0.1"
          container.port = port
          containers.create(container)
        else
          container.port = port      
          containers.update(container)  
        end
  
        system("cd /var/harbr/#{manifest.name}/next && bundle install")
        system("sv restart next.#{manifest.name}")
        puts "Started container: next.#{manifest.name}"
        create_traefik_config(containers.all)
      end
  
      def perform(container, version)
        puts "Running tasks for container: 'next.#{container}', Version: '#{version}'"
        manifest = load_manifest(container, version)
        puts "Manifest: #{manifest}"
        system("ln -sf /var/harbr/#{container}/versions/#{version} /var/harbr/#{container}/next")
        run_container(manifest)
      end
    end
  end
end
