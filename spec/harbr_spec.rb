# frozen_string_literal: true

RSpec.describe Harbr do
end

module Runit
  class Run
    def initialize(container, port)
      @container_name = container
      @port = port
    end

    def to_s
      script_template = <<~SCRIPT
        #!/bin/sh
        exec 2>&1
        cd /var/harbr/#{@container_name}/current
        exec ./exe/run #{@port}
      SCRIPT
    end

    def link
      "ln -s /etc/sv/harbr/#{@container_name} /etc/service/#{@container_name}"
    end
  end

  class Log
    def initialize(container, port)
      @container_name = container
    end

    def to_s
      script_template = <<~SCRIPT
        #!/bin/sh
        exec svlogd -tt /var/log/harbr/#{@container_name}/next/
      SCRIPT
    end

    def link
      "ln -s /etc/sv/harbr/#{@container_name}/log /etc/service/next.#{@container_name}/log"
    end
  end

  module Next
    class Run
      def initialize(container, port)
        @container_name = container
        @port = port
      end

      def to_s
        script_template = <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          cd /var/harbr/#{@container_name}/next
          exec ./exe/run #{@port}
        SCRIPT
      end

      def link
        "ln -s /etc/sv/harbr/#{@container_name}/next /etc/service/next.#{@container_name}"
      end
    end
  end

  RSpec.describe "Next" do
    def highest_numbered_directory(path)
      directories = Dir.glob("#{path}/*").select { |entry| File.directory?(entry) }
      directories.max_by { |entry| entry[/\d+/].to_i }
    end

    it "should create a run script" do
      path = highest_numbered_directory("spec/var/harbr/test")
      expect(path).to eq "spec/var/harbr/test/6"
    end
  end

  RSpec.describe Runit::Run do
    it "should create a run script" do
      container_name = "test"
      port = 3000

      run = Runit::Run.new(container_name, port)
      expect(run.to_s).to eq <<~SCRIPT
        #!/bin/sh
        exec 2>&1
        cd /var/harbr/#{container_name}/current
        exec ./exe/run #{port}
      SCRIPT
    end

    it "should link the service" do
      container_name = "test"
      port = 3000
      run = Runit::Run.new(container_name, port)
      expect(run.link).to eq "ln -s /etc/sv/harbr/#{container_name} /etc/service/#{container_name}"
    end

    context "Next" do
      it "should create a run script" do
        container_name = "test"
        port = 3000

        run = Runit::Next::Run.new(container_name, port)
        expect(run.to_s).to eq <<~SCRIPT
          #!/bin/sh
          exec 2>&1
          cd /var/harbr/#{container_name}/next
          exec ./exe/run #{port}
        SCRIPT
      end

      it "should link the service" do
        container_name = "test"
        port = 3000
        run = Runit::Next::Run.new(container_name, port)
        expect(run.link).to eq "ln -s /etc/sv/harbr/#{container_name}/next /etc/service/next.#{container_name}"
      end
    end
  end
end
