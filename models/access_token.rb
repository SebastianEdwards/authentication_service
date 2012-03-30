require_relative './redis_model'

class AccessToken < RedisModel
  namespace :access_token
  id_type :secure_random_16
  expires_in 900 # 15 minutes
end
