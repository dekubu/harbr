# frozen_string_literal: true

RSpec.describe Harbr do
end

RSpec.describe Harbr::Pool do
  it "should have 1000 ports" do
    pool = Harbr::Pool.new
    expect(pool.ports.count).to eq(1001)
  end
  it "should get port" do
    pool = Harbr::Pool.new
    port = pool.get_port("vidtreon.harbr.zer2one.ee")
    expect(port.host_header).to eq("vidtreon.harbr.zer2one.ee")
  end
  it "should return port" do
    pool = Harbr::Pool.new
    port = pool.get_port("sild.harbr.zer2one.ee")
    expect(port.host_header).to eq("sild.harbr.zer2one.ee")
    expect(pool.return_port(port)).to be_truthy
  end
end

Manifest = Struct.new(:host, :version,:name)
RSpec.describe Harbr::Job do
  it "should assign port" do
    manifest = Manifest.new("test.harbr.zer2one.ee", 1, "test")
    Harbr::Job.new.perform(manifest)
  end
end
