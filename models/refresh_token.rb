require_relative './redis_model'

class RefreshToken < RedisModel
  namespace :refresh_token
  id_type :secure_random_16
  expires_in 1296000 # 15 days
end
