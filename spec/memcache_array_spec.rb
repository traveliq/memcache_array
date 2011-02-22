$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'memcache_array'

class MockClient < Hash
  def read(key)
    self[key]
  end
  def write(key, value)
    self[key] = value
  end
end

describe MemcacheArray, 'expose its key' do

  it 'should expose its key' do
    client = MockClient.new
    array = MemcacheArray.new('the_key', client)
    array.key.should == 'the_key'
  end
  
end

describe MemcacheArray, 'finding indices' do

  before :each do
    @client = MockClient.new
    @client['the_key_indices'] = [0,1,2,3]
    @array_few = MemcacheArray.new('the_key', @client)
  end
  
  it 'should find the and lock the next index' do
    @array_few.next_index.should == 4
    @client['the_key_indices'].should == [0,1,2,3,4]
  end
  
end

describe MemcacheArray, 'deleting indices' do

  before :each do
    @client = MockClient.new
    @client['the_key_indices'] = [0,1,2,3]
    @array = MemcacheArray.new('the_key', @client)
  end
  
  it 'should find the and lock the next index' do
    @client.should_receive(:write).with('the_key_indices', [0, 1, 3])
    @array.delete_index(2)
  end
  
end

describe MemcacheArray, 'deleting data' do

  before :each do
    @client = MockClient.new
    @array = MemcacheArray.new('the_key', @client)
  end
  
  it 'should find the and lock the next index' do
    @array.should_receive(:delete_index).with(2)
    @client.should_receive(:delete).with('the_key_2')
    @array.delete_bucket(2)
  end
  
end

describe MemcacheArray, 'writing' do

  it 'should write' do
    client = mock('Client')
    array = MemcacheArray.new('the_key', client)
    array.should_receive(:next_index).and_return(4)
    client.should_receive('write').with('the_key_4', ['the_data'])
    array << ['the_data']
  end
  
  it 'should write metadata' do
    client = mock('Client')
    array = MemcacheArray.new('the_key', client)
    array.should_receive(:next_index).and_return(4)
    client.should_receive(:write).with('the_key_4_meta', 'metadata')
    client.should_receive(:write).with('the_key_4', ['the_data'])
    array.<<(['the_data'], 'metadata')
  end
  
  it 'should raise an error when no array is passed' do
    client = mock('Client')
    array = MemcacheArray.new('the_key', client)
    lambda {array << 'lala!'}.should raise_error
  end
    
end

describe MemcacheArray, 'reading' do

  before :each do
    @client = MockClient.new
    @client['the_key_indices'] = [0,1,2]
    @client['the_key_0'] = ['null', 'zero']
    @client['the_key_1'] = ['one']
    @client['the_key_2'] = ['two']
    @array = MemcacheArray.new('the_key', @client)
  end
  
  it 'should read continous elements' do
    @array.all.should == ['null', 'zero','one', 'two']
  end
  
  it 'should ignore nil elements' do
    @client['the_key_indices'] = [0,1,2,3,4,5]
    @client['the_key_5'] = ['five']
    @array.all.should == ['null', 'zero', 'one', 'two', 'five']
  end
  
end

describe MemcacheArray, 'reading with deleting' do

  before :each do
    @client = MockClient.new
    @client['the_key_indices'] = [0,1,2]
    @client['the_key_0'] = ['null', 'zero']
    @client['the_key_1'] = ['one']
    @client['the_key_2'] = ['two']
    @array = MemcacheArray.new('the_key', @client)
  end
  
  it 'should read continous elements' do
    @array.all(:delete => true).should == ['null', 'zero','one', 'two']
  end
    
  it 'should read continous elements' do
    @client.should_receive(:delete).with('the_key_0')
    @client.should_receive(:delete).with('the_key_1')
    @client.should_receive(:delete).with('the_key_2')
    @array.all(:delete => true)
  end
    
end

describe MemcacheArray, 'reading with metadata' do

  before :each do
    @client = MockClient.new
    @client['the_key_indices'] = [0,1,2,3]
    @client['the_key_0'] = ['null', 'zero']
    @client['the_key_0_meta'] = 0
    @client['the_key_1'] = ['one']
    @client['the_key_1_meta'] = 1
    @client['the_key_2'] = ['two']
    @client['the_key_2_meta'] = 2
    @client['the_key_3'] = ['three']
    @array = MemcacheArray.new('the_key', @client)
  end
  
  it 'should respect block when getting elements' do
    @array.all{|m| m > 0}.should == ['one', 'two']
  end
  
end

describe MemcacheArray, 'deleting with metadata' do

  before :each do
    @client = MockClient.new
    @client['the_key_indices'] = [0,1,2]
    @client['the_key_0'] = ['null', 'zero']
    @client['the_key_0_meta'] = 0
    @client['the_key_1'] = ['one']
    @client['the_key_1_meta'] = 1
    @client['the_key_2'] = ['two']
    @client['the_key_2_meta'] = 2
    @array = MemcacheArray.new('the_key', @client)
  end
  
  it 'should delete all data' do
    @client.should_receive(:delete).with('the_key_0')
    @client.should_receive(:delete).with('the_key_1')
    @client.should_receive(:delete).with('the_key_2')
    @client.should_receive(:delete).with('the_key_0_meta')
    @client.should_receive(:delete).with('the_key_1_meta')
    @client.should_receive(:delete).with('the_key_2_meta')
    @client.should_receive(:delete).with('the_key_indices')
    @array.delete!
  end
  
end