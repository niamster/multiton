require_relative '../multiton'

describe Multiton do
  before :each do
    class A < Multiton
    end
  end

  after :each do
    Object.send(:remove_const, :A)
    Object.send(:remove_const, :B) if defined? B
  end

  describe '#create' do
    it "returns same instance of a class for given ID" do
      a, b = A.create(:some_id), A.create(:some_id)
      expect(a).to eq(b)
    end

    it "created instance survives GC work" do
      a = A.create(:some_id)
      a_oid = a.object_id
      a = nil
      GC.start
      ObjectSpace.garbage_collect
      a = A.create(:some_id)
      expect(a_oid).to eq(a.object_id)
    end

    it "never collides on IDs for different classes" do
      class B < Multiton
      end
      a, b = A.create(:some_id), B.create(:some_id)
      expect(a).not_to eq(b)
    end
  end

  describe '#[]' do
    it "is an alias to #create" do
      expect(A.create(:some_id)).to eq(A[:some_id])
    end
  end

  it "creates instance for given ID on demand" do
    expect(ObjectSpace.each_object(A){}).to eq(0)
    A.create(:some_id)
    expect(ObjectSpace.each_object(A){}).to eq(1)
  end

  it "impossible to inherit Multiton-derived class" do
    expect {
      class B < A
      end
    }.to raise_error
  end

  it "impossible to create an instance with Multiton.new" do
    expect {
      a = A.new :some_id
    }.to raise_error
  end

  it "impossible to access #instance of included Singleton module" do
    expect {
      a = A.instance
    }.to raise_error
  end

  describe '@id' do
    it "instance variable @id is available before the call to #initialize" do
      class B < Multiton
        attr_reader :local_id
        def initialize
          @local_id = @id
        end
      end
      b = B.create(:some_id)
      expect(b.local_id).to eq(:some_id)
      expect(b.id).to eq(:some_id)
      expect(b.local_id).to eq(b.id)
    end
  end
end
