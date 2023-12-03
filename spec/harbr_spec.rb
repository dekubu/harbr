# frozen_string_literal: true

RSpec.describe Harbr do
  
end


RSpec.describe Harbr::Port::Pool do

  it 'should have 1000 ports' do
    pool = Harbr::Port::Pool.new
    expect(pool.ports.count).to eq(1001)
  end
  it 'should have 1000 ports' do
    pool = Harbr::Port::Pool.new
    port = pool.get_port("vidtreon.harbr.zer2one.ee")        
    p port
    expect(pool.ports.count).to eq(1001)
    
  end
end
