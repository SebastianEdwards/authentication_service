require 'securerandom'

class RedisModel
  attr_accessor :attributes
  attr_reader :id

  def self.create(attributes = {})
    object = self.new(attributes)

    object.save ? object : false
  end

  def self.create!(attributes = {}, status = 400, msg = "Error creating object.")
    create(attributes) or raise Goliath::Validation::Error.new(status, msg)
  end

  def self.find(id)
    if json = REDIS.get("#{namespace}:#{id}")
      attributes = JSON.parse(json)
      self.new(attributes, id)
    end
  end

  def self.find!(id, status = 400, msg = "Invalid ID.")
    find(id) or raise Goliath::Validation::Error.new(status, msg)
  end

  def self.namespace(namespace = nil)
    @namespace = namespace if namespace
    @namespace
  end

  def namespace
    self.class.namespace
  end

  def self.expires_in(expires_in = nil)
    @expires_in = expires_in if expires_in
    @expires_in
  end

  def expires_in
    self.class.expires_in
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
    generate_secure_random(4)
  end

  def self.generate_secure_random_16_id
    generate_secure_random(8)
  end

  def initialize(attributes = {}, id = nil)
    @attributes = attributes
    @id = id
  end

  def valid?; true; end

  def before_validation; end

  def after_save; end

  def save
    before_validation
    if valid?
      @id ||= self.class.generate_id
      key = "#{namespace}:#{@id}"
      if 'OK' == REDIS.set(key, attributes.to_json)
        after_save
        if expires_in
          REDIS.expire(key, expires_in)
        else
          true
        end
      end
    else
      raise "Invalid attributes".inspect
    end
  end

  def method_missing(method_sym)
    key = method_sym.to_s
    if attributes.has_key?(key)
      attributes[key]
    else
      super
    end
  end

  def to_json
    if @id
      attributes.merge({id: @id}).to_json  
    else
      attributes.to_json
    end
  end
end
