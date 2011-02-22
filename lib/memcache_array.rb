class MemcacheArray
  
  attr_reader :key
  
  def initialize(key, client = nil)
    @key = key
    @client = client || Rails.cache
  end
  
  def <<(data, metadata = nil)
    raise ArgumentError, "You can only append arrays." unless data.is_a? Array
    index = next_index
    @client.write(metadata_key_with_index(index), metadata) if metadata
    @client.write(key_with_index(index), data)
  end

  def all(options = {})
    delete = options[:delete]
    indices.inject([]) do |accumulator, i|
      key = key_with_index(i)
      include_data = 
      if block_given?
        metadata = @client.read(metadata_key_with_index(i))
        metadata ? yield(metadata) : false
      else
        true
      end
      if include_data
        value = @client.read(key)
        delete_bucket(i) if delete
        accumulator += value.is_a?(Array) ? value : []
      else
        accumulator
      end
    end    
  end

  def delete!
    indices.each do |i|
      @client.delete(key_with_index(i))
      @client.delete(metadata_key_with_index(i))
    end
    @client.delete(index_key)
  end
  
  def delete_bucket(index)
    delete_index(index)
    @client.delete(key_with_index(index))
  end
  
  def next_index
    indices_new = indices.dup || []
    indices_new << (indices.last || -1) + 1
    @client.write(index_key, indices_new)
    indices.last  
  end

  def delete_index(index)
    @client.write(index_key, (indices - [index]))    
  end

  def indices
    @client.read(index_key) || []
  end
  
  def index_key
    "#{@key}_indices"
  end
    
  def key_with_index(index)
    "#{@key}_#{index}"
  end
  
  def metadata_key_with_index(index)
    "#{key_with_index(index)}_meta"
  end
  
end
