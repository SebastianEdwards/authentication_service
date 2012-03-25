module TokensController
  def self.included(base)
    base.post '/token', Create
  end

  class Create < Goliath::API
    def code_grant_type
      if code_json = REDIS.get("code:#{params[:code]}")
        code_hash = JSON.parse(code_json)
        user = User.find(code_hash['user_id'])
        refresh_token = SecureRandom.hex
        access_token = SecureRandom.hex
        access_token_json = user.to_json only:
          [:authenticatable_id, :authenticatable_type]
        REDIS.set "refresh_token:#{refresh_token}", access_token_json
        REDIS.set "access_token:#{access_token}", access_token_json
        REDIS.set "access_token:#{access_token}:user_id", user.id
        REDIS.set "access_token:#{access_token}:refresh_token", refresh_token
        response = {access_token: access_token, refresh_token: refresh_token}
        [200, {'Content-Type' => 'application/JSON'}, response.to_json]
      end
    end

    def no_grant_type
      error = {error: 'No grant type specified.'}
      [400, {'Content-Type' => 'application/JSON'}, error.to_json]
    end

    def response(env)
      case params[:grant_type]
      when 'code'
        code_grant_type
      when 'refresh_token'
        refresh_token_grant_type
      when 'password'
        password_grant_type
      else
        no_grant_type
      end
    end
  end
end
