require_relative './redis_model'

class RefreshToken < RedisModel
  namespace :refresh_token
  id_type :secure_random_16
end
