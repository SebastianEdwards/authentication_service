require_relative './redis_model'

class AccessToken < RedisModel
  namespace :access_token
  id_type :secure_random_16
  expires_in 900 # 15 minutes

  def resource_owner_id!(status = 400, msg = "Active access token does not have an associated user.")
    if attributes.has_key?("resource_owner_id")
      resource_owner_id
    else
      raise Goliath::Validation::Error.new(status, msg)
    end
  end
end
