module TokensController
  def self.included(base)
    base.post '/tokens', Create
  end

  GRANT_TYPES = %w{code refresh_token password}

  class Create < Goliath::API
    use Goliath::Rack::Validation::RequiredParam, {
      :key => 'grant_type',
      :message => 'parameter missing.'
    }
    use Goliath::Rack::Validation::RequiredValue, {
      :key => 'grant_type',
      :values => GRANT_TYPES
    }

    def code_grant_type
      if code = Code.find(params[:code])
        access_token = AccessToken.new code.attributes
        refresh_token = RefreshToken.new code.attributes
        if access_token.save && refresh_token.save
          response = {
            access_token: access_token.id,
            refresh_token: refresh_token.id
          }
          [200, {'Content-Type' => 'application/JSON'}, response.to_json]
        end
      else
        message = "Invalid or expired code."
        raise Goliath::Validation::Error.new(400, message)
      end
    end

    def refresh_token_grant_type
      if refresh_token = RefreshToken.find(params[:refresh_token])
        access_token = AccessToken.new refresh_token.attributes
        refresh_token = RefreshToken.new refresh_token.attributes
        if access_token.save && refresh_token.save
          response = {
            access_token: access_token.id,
            refresh_token: refresh_token.id
          }
          [200, {'Content-Type' => 'application/JSON'}, response.to_json]
        end
      else
        message = "Invalid or expired refresh_token."
        raise Goliath::Validation::Error.new(400, message)
      end
    end

    def password_grant_type
      key = "#{params[:username]}:#{params[:password]}"
      if user_id = REDIS.hget('password', key)
        attributes = {user_id: user_id, client_id:1}
        access_token = AccessToken.new attributes
        refresh_token = RefreshToken.new attributes
        if access_token.save && refresh_token.save
          response = {
            access_token: access_token.id,
            refresh_token: refresh_token.id
          }
          [200, {'Content-Type' => 'application/JSON'}, response.to_json]
        end
      else
        message = "Invalid credentials."
        raise Goliath::Validation::Error.new(400, message)
      end
    end

    def response(env)
      case params[:grant_type]
      when 'code'
        code_grant_type
      when 'refresh_token'
        refresh_token_grant_type
      when 'password'
        password_grant_type
      end
    end
  end
end
