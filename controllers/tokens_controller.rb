module TokensController
  def self.included(base)
    base.post '/tokens', Create
  end

  GRANT_TYPES = %w{code refresh_token password client_credentials}

  class Create < Goliath::API
    %w{grant_type client_id client_secret}.each do |attribute|
      use Goliath::Rack::Validation::RequiredParam, {
        :key => attribute,
        :message => 'parameter missing.'
      }
    end
    use Goliath::Rack::Validation::RequiredValue, {
      :key => 'grant_type',
      :values => GRANT_TYPES
    }

    def code_grant_type(client)
      if code = Code.find!(params[:code], 400, "Invalid or expired code.")
        access_token = AccessToken.create! code.attributes
        refresh_token = RefreshToken.create! code.attributes
        response = {
          access_token: access_token.id,
          refresh_token: refresh_token.id
        }
        [200, {'Content-Type' => 'application/JSON'}, response.to_json]
      end
    end

    def refresh_token_grant_type(client)
      if refresh_token = RefreshToken.find!(params[:refresh_token], 400, "Invalid or expired refresh_token.")
        access_token = AccessToken.create! refresh_token.attributes
        refresh_token = RefreshToken.create! refresh_token.attributes
        response = {
          access_token: access_token.id,
          refresh_token: refresh_token.id
        }
        [200, {'Content-Type' => 'application/JSON'}, response.to_json]
      end
    end

    def password_grant_type(client)
      if user = User.find_by_username_and_password!(params[:username], params[:password])
        attributes = {user_id: user.id, client_id: client.id}
        access_token = AccessToken.create! attributes
        refresh_token = RefreshToken.create! attributes
        response = {
          access_token: access_token.id,
          refresh_token: refresh_token.id
        }
        [200, {'Content-Type' => 'application/JSON'}, response.to_json]
      end
    end

    def client_credentials_grant_type(client)
      access_token = AccessToken.create!({client_id: client.id})
      response = {access_token: access_token.id}
      [200, {'Content-Type' => 'application/JSON'}, response.to_json]
    end

    def response(env)
      client = Client.find! params[:client_id]
      client.validate_secret! params[:client_secret]
      case params[:grant_type]
        when 'code' then code_grant_type(client)
        when 'refresh_token' then refresh_token_grant_type(client)
        when 'password' then password_grant_type(client)
        when 'client_credentials' then client_credentials_grant_type(client)
      end
    end
  end
end
