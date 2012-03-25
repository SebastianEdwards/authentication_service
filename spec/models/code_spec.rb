require './models/code'

describe 'Code' do
  it 'should have namespace code' do
    c = Code.new
    c.namespace.should equal :code
  end

  it 'should generate an 8 character id' do
    Code.generate_id.length.should equal 8
  end
end