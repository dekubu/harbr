require "yaml"
require "ostruct"
require "sucker_punch"

require "harbr"
module Harbr
  module Next
    class Job
      include SuckerPunch::Job


      def check
        sleep_times = [1, 3, 5, 8, 23]
        begin
          result = yield if block_given?
          unless result
            sleep_times.each do |time|
              result = yield if block_given?
              break if result
              sleep(time)
            end
          end
        rescue => e
          puts "Error: #{e.message}"
        end
      end

      def get_container_name(path)
        File.basename(path)
      end

      def create_traefik_config(containers)
        config = {
          "http" => {
            "routers" => {
              "traefik-dashboard" => {
                "rule" => "Host(`traefik.harbr.zero2one.ee`)",
                "service" => "api@internal",
                "tls" => {}  # Enable TLS for the dashboard
              }
            },
            "services" => {}
          }
        }

        containers.each do |container|
          container.ip = "127.0.0.1"
          name = container.name.tr(".", "-")

          # Create the router with TLS enabled and specific format
          router_key = "#{name}-router-secure"
          config["http"]["routers"][router_key] = {
            "rule" => "Host(`#{container.host_header}`)",
            "service" => "#{name}-service",
            "entryPoints" => ["https"],
            "tls" => {
              "certResolver" => "myresolver"  # Use a custom certificate resolver
            }
          }

          # Create the service
          config["http"]["services"]["#{name}-service"] = {
            "loadBalancer" => {
              "servers" => [{"url" => "http://#{container.ip}:#{container.port}"}]
            }
          }
        end

        # Write the configuration to a TOML file
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

      module Runit
        class Run
          def initialize(container, port)
            @container_name = container
            @port = port
          end

          def to_s
            <<~SCRIPT
              #!/bin/sh
              exec 2>&1
              cd /var/harbr/#{@container_name}/current
              exec ./exe/run #{@port} live
            SCRIPT
          end

          def link
            "ln -s /etc/sv/harbr/#{@container_name} /etc/service/#{@container_name}"
          end
        end

        class Finish
          def initialize(port)
            @port = port
          end

          def to_s
            <<~SCRIPT
              #!/bin/sh
              sleep 3
              `lsof -i :#{@port} | awk 'NR!=1 {print $2}' | xargs kill`
            SCRIPT
          end
        end

        class Log
          def initialize(container, port)
            @container_name = container
          end

          def to_s
            <<~SCRIPT
              #!/bin/sh
              exec svlogd -tt /var/log/harbr/#{@container_name}/next/
            SCRIPT
          end
        end

        module Next
          class Run
            def initialize(container, port)
              @container_name = container
              @port = port
            end

            def to_s
              <<~SCRIPT
                #!/bin/sh
                exec 2>&1
                cd /var/harbr/containers/#{@container_name}/next
                exec ./exe/run #{@port} next
              SCRIPT
            end
          end

          class Log
            def initialize(container)
              @container_name = container
            end

            def to_s
              <<~SCRIPT
                #!/bin/sh
                exec svlogd -tt /var/log/harbr/#{@container_name}/next/
              SCRIPT
            end
          end
        end
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

      def check
        sleep_times = [1, 3, 5, 8, 23]
        begin
          result = yield if block_given?
          unless result
            sleep_times.each do |time|
              result = yield if block_given?
              break if result
              sleep(time)
            end
          end
        rescue => e
          puts "Error: #{e.message}"
        end
      end

      def perform(name, version)
        Harbr.notifiable(name, version) do
          manifest = load_manifest(name, version)
          current_path = "/var/harbr/containers/#{name}/versions/#{version}"

          port = `port assign next.#{manifest.port}`.strip
          
          check do
            puts "Waiting for container #{current_path} 5to be available..."
            Dir.exist?(current_path)
          end

          Dir.chdir current_path do
            system "sv stop next.#{name}"
            if File.exist?("Gemfile")
              `bundle config set --local path 'vendor/bundle'`
              system "bundle install"
            end

            `mkdir -p /etc/sv/harbr/#{name}/next`
            `mkdir -p /etc/sv/harbr/#{name}/next/log`
            `mkdir -p /var/log/harbr/#{name}/next/log`

            write_to_file "/etc/sv/harbr/#{name}/next/run", Runit::Next::Run.new(name, port).to_s
            write_to_file "/etc/sv/harbr/#{name}/next/finish", Runit::Finish.new(port).to_s
            write_to_file "/etc/sv/harbr/#{name}/next/log/run", Runit::Next::Log.new(name).to_s

            `chmod +x /etc/sv/harbr/#{name}/next/run`
            `chmod +x /etc/sv/harbr/#{name}/next/log/run`
            `chmod +x /etc/sv/harbr/#{name}/next/finish`

            system "rm /etc/service/next.#{name}"
            system "rm /var/harbr/containers/#{name}/next"

            system "ln -sf /var/harbr/containers/#{name}/versions/#{version} /var/harbr/containers/#{name}/next"
            system "ln -sf /etc/sv/harbr/#{name}/next /etc/service/next.#{name}"

            `rsync -av /var/dddr/#{name}/live  /var/dddr/#{name}/next`
            puts "sync live data to next"

            system "sv restart next.#{name}"
          end

          containers = collate_containers("next.#{name}", "next.#{manifest.host}", port)
          create_traefik_config(containers)
          puts "harbr: #{version} of #{name} into next environment"
        end
      end
    end
  end
end
