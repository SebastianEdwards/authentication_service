require 'digest/sha1'

class ResourceOwner < RedisModel
  namespace :resource_owner
  id_type :sequential

  def self.hash(string)
    Digest::SHA1.hexdigest string
  end

  def self.find_by_username_and_password(username, password)
    password_digest = hash(password)
    key = "#{username}:#{password_digest}"
    
    find_by_provider_and_uid "password", key
  end

  def self.find_by_username_and_password!(username, password, status = 400, msg = "Invalid credentials.")
    find_by_username_and_password(username, password) or raise Goliath::Validation::Error.new(status, msg)
  end

  def self.find_by_provider_and_uid(provider_name, uid)
    resource_owner_id = REDIS.hget(provider_name, uid)
    
    resource_owner_id ? find(resource_owner_id) : nil
  end

  def self.find_by_provider_and_uid!(provider_name, uid, status = 400, msg = "No matching resource_owner.")
    find_by_provider_and_uid(provider_name, uid) or raise Goliath::Validation::Error.new(status, msg)
  end

  def associate_with_provider!(provider_name, provider_uid)
    REDIS.HSET provider_name, provider_uid, @id
  end

  def valid?
    attributes.select do |key, value|
      key == 'password' ||
      key.match(/_confirmation$/)
    end.length == 0
  end

  def check_confirmation_attributes!
    attributes.select { |k, v| k.match /_confirmation$/ }.each do |key, value|
      matching_key = key.gsub(/_confirmation$/, '')
        if value == attributes[matching_key]
          attributes.delete key
        else
          message = "#{key} does not match #{matching_key}."
          raise Goliath::Validation::Error.new(400, message)
      end
    end
  end

  def hash_password!
    @password_digest = self.class.hash(password)
    attributes.delete 'password'
  end

  def before_validation
    check_confirmation_attributes!
    hash_password! if attributes.has_key?('password')
  end

  def after_save
    if @password_digest
      REDIS.hset "password", "#{username}:#{@password_digest}", @id
    end
  end
end
