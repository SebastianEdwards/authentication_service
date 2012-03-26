require './models/code'

describe 'Code' do
  it 'should have namespace code' do
    Code.namespace.should equal :code
  end

  it 'should generate an 8 character id' do
    Code.generate_id.length.should equal 8
  end

  %w{client_id}.map(&:to_sym).each do |attribute|
    it "should be not be valid if missing #{attribute}" do
      code = Code.new
      code.valid?.should_not be_true
    end
  end

  it "should be valid when has client_id and user_id" do
    code = Code.new(client_id: 1, user_id: 1)
    code.valid?.should be_true
  end
end
