require_relative './redis_model'

class TempOauthStore < RedisModel
  namespace :temp_oauth_store
  id_type :secure_random_16
  expires_in 30
end
