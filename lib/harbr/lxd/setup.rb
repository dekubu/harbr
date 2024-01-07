module Harbr
  module Lxd
    class Setup
      include SuckerPunch::Job

      def perform(name)
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

        puts "Container #{name} created."

        # Publish the container as an image named "panamax"
        system("lxc stop #{name}")
        system("lxc publish #{name} --alias @#{name}")

        puts "panamax image #{name} published."

      end
    end
  end
end