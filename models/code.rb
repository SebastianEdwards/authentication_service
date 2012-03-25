require_relative './redis_model'

class Code < RedisModel
  namespace :code
  id_type :secure_random_8

  def valid?
    attributes.has_key?(:client_id) && attributes.has_key?(:user_id)
  end
end
