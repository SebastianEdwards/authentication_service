class BaseModel
  attr_accessor :attributes

  def self.find(key)
    json = REDIS.get("#{@namespace}:#{key}")
    attributes = JSON.parse(json)
    self.new(attributes, :new_record => false)
  end

  def self.namespace(namespace)
    @namespace = namespace
  end

  def self._namespace
    @namespace
  end

  def initialize(attributes = {}, key = nil)
    @attributes = attributes
    @key = key
  end

  def valid?; true; end

  def save
    if valid?
      @key = REDIS.model_save [self.class._namespace, @key, attributes.to_json]
    else
      raise "Error".inspect
    end
  end

  def to_json
    (@key ? attributes.merge(id: @key) : attributes).to_json
  end
end
