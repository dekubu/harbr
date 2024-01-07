require "fileutils"

module Harbr
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
          echo "started #{@container_name} on port #{@port}"
        SCRIPT
      end

      def finish_script
        <<~SCRIPT
          #!/bin/sh
          lsof -i :#{@port} | awk 'NR!=1 {print $2}' | xargs kill
          echo "killed #{@container_name} on port #{@port}"
        SCRIPT
      end

      def log_script
        <<~SCRIPT
          #!/bin/sh
          echo "starting log for #{@container_name} on port #{@port}"
          exec svlogd -tt /var/log/harbr/#{@container_name}/#{@env}
        SCRIPT
      end
    end
  end
  module Lxd
    class Job
      include SuckerPunch::Job

      def perform(name, version, env, port)
        ip_address = lxd_pack(name, env, port)
        puts "Container IP Address: #{ip_address}"
      end

      private

      def lxd_pack(name, env, port)
        base_path = "/var/harbr/containers/paiddm"
        source_path = File.join(base_path, env)
        runit_script = Runit::Script.new(name, port, env)

        # Check if the source path exists
        raise "Source path #{source_path} does not exist." unless File.directory?(source_path)

        # Create the container
        system("lxc launch ubuntu:20.04 #{name}")
        sleep(5) # Wait for the container to initialize

        # Check if runit is installed, if not then install
        unless system("lxc exec #{name} -- dpkg -s runit")
          system("lxc exec #{name} -- apt-get update")
          system("lxc exec #{name} -- apt-get install -y runit")
        end

        # Check if chruby is installed, if not then install chruby, ruby-install and Ruby versions
        unless system("lxc exec #{name} -- bash -c 'type chruby'")
          system("lxc exec #{name} -- apt-get install -y git curl build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libgdbm-dev libncurses5-dev libffi-dev")
          system("lxc exec #{name} -- wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz")
          system("lxc exec #{name} -- tar -xzvf chruby-0.3.9.tar.gz")
          system("lxc exec #{name} -- cd chruby-0.3.9/ && make install")
          system("lxc exec #{name} -- echo 'source /usr/local/share/chruby/chruby.sh' >> ~/.bashrc")
          system("lxc exec #{name} -- wget -O ruby-install-0.8.3.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.3.tar.gz")
          system("lxc exec #{name} -- tar -xzvf ruby-install-0.8.3.tar.gz")
          system("lxc exec #{name} -- cd ruby-install-0.8.3/ && make install")

          # Install Ruby versions
          ["3.2.2", "3.1.2", "3.3.0"].each do |ruby_version|
            system("lxc exec #{name} -- ruby-install ruby #{ruby_version}")
          end
        end
        # Copy the entire directory structure to the container
        system("lxc file push -r #{source_path}/* #{name}/var/harbr/containers/#{name}/")

        # Start the container, if it's not already running
        system("lxc start #{name}")
        sleep(5) # Wait for the container to fully start

        # Create Runit scripts and directories
        sv_path = "/etc/sv/#{name}"
        system("lxc exec #{name} -- mkdir -p #{sv_path}")
        system("lxc exec #{name} -- mkdir -p /var/log/harbr/#{name}/#{env}")

        # Create and set execute permissions on each script
        ["run_script", "finish_script", "log_script"].each do |script_method|
          script_content = runit_script.send(script_method)
          File.write("tmp_script.sh", script_content)
          system("lxc file push tmp_script.sh #{name}#{sv_path}/#{script_method.gsub("_script", "")}")
          system("lxc exec #{name} -- chmod +x #{sv_path}/#{script_method.gsub("_script", "")}")
          File.delete("tmp_script.sh")
        end

        # Symlink from source to /etc/sv
        system("lxc exec #{name} -- ln -s #{source_path} /etc/sv/#{name}")

        # Symlink from sv to /etc/service
        system("lxc exec #{name} -- ln -s #{sv_path} /etc/service/#{name}")

        # Fetch the container's IP address
        ip_address = `lxc list #{name} -c 4 --format csv`.strip

        puts "Container #{name} created on #{ip_address}, Runit scripts set up, and started."
        ip_address
      end
    end
  end
end
