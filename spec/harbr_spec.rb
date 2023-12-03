# frozen_string_literal: true

RSpec.describe Harbr do
  
end


RSpec.describe Harbr::Port::Pool do

  it 'should have 100 ports' do
    
    pool = Harbr::Port::Pool.new

    expect(pool.ports.count).to eq(1001)

  end
end
