# frozen_string_literal: true

RSpec.describe Harbr do
end

Manifest = Struct.new(:host, :version,:name,:port)
RSpec.describe Harbr::Job do
  it "should assign port" do
    manifest = Manifest.new("test.harbr.zer2one.ee", 1, "test", 3000)
    Harbr::Job.new.perform(manifest)
  end
end
