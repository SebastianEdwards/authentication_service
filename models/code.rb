require_relative './redis_model'

class Code < RedisModel
  namespace :code
  id_type :secure_random_8
  expires_in 15

  def valid?
    attributes.has_key?(:client_id) && attributes.has_key?(:resource_owner_id)
  end
end
