require 'securerandom'

class RedisModel
  attr_accessor :attributes
  attr_reader :id

  def self.find(id)
    if json = REDIS.get("#{namespace}:#{id}")
      attributes = JSON.parse(json)
      self.new(attributes, id)
    end
  end

  def self.namespace(namespace = nil)
    @namespace = namespace if namespace
    @namespace
  end

  def namespace
    self.class.namespace
  end

  def self.generate_id
    send "generate_#{@id_type}_id"
  end

  def self.id_type(type)
    if respond_to? "generate_#{type}_id"
      @id_type = type
    else
      raise "Invalid ID type".inspect
    end
  end

  def self.generate_sequential_id
    REDIS.incr "#{namespace}:latest_id"
  end

  def self.generate_secure_random(length)
    SecureRandom.hex(length)
  end

  def self.generate_secure_random_8_id
    generate_secure_random(8)
  end

  def self.generate_secure_random_16_id
    generate_secure_random(16)
  end

  def initialize(attributes = {}, id = nil)
    @attributes = attributes
    @id = id
  end

  def valid?; true; end

  def save
    if valid?
      @id ||= self.class.generate_id
      'OK' == REDIS.set("#{namespace}:#{@id}", attributes.to_json)
    else
      raise "Invalid attributes".inspect
    end
  end

  def to_json
    (@id ? attributes.merge(id: @id) : attributes).to_json
  end
end
