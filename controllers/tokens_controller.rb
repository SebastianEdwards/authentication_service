module TokensController
  def self.included(base)
    base.post '/token', Create
    base.get '/token', Index
  end

  GRANT_TYPES = %w{code refresh_token password client_credentials}

  class Index < Goliath::API
    def response(env)
      headers = {
        'Content-Type' => 'application/vnd.collection+json',
        'Cache-Control' => 'max-age=3600, must-revalidate'
      }

      response = CollectionJSON.generate_for('/token') do |builder|
        builder.set_template do |template|
          template.add_data 'client_id', prompt: 'Client ID'
          template.add_data 'client_secret', prompt: 'Client secret'
          template.add_data 'grant_type', prompt: 'Token grant type'
          template.add_data 'code', prompt: 'Code'
          template.add_data 'username', prompt: 'Username'
          template.add_data 'password', prompt: 'Password'
          template.add_data 'refresh_token', prompt: 'Refresh token'
          template.add_data 'scope', prompt: 'Scope'
        end
      end

      [200, headers, response.to_json]
    end
  end

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

    def code_grant_type(client, granted_scope)
      if code = Code.find!(params[:code], 400, "Invalid or expired code.")
        access_token = AccessToken.create! code.attributes
        refresh_token = RefreshToken.create! code.attributes
        response = {
          access_token: access_token.id,
          expires_in: AccessToken.expires_in,
          refresh_token: refresh_token.id,
          scope: access_token.scope,
          token_type: "bearer"
        }
        [200, {'Content-Type' => 'application/json'}, response.to_json]
      end
    end

    def refresh_token_grant_type(client, granted_scope)
      if refresh_token = RefreshToken.find!(params[:refresh_token], 400, "Invalid or expired refresh_token.")
        access_token = AccessToken.create! refresh_token.attributes
        refresh_token = RefreshToken.create! refresh_token.attributes
        response = {
          access_token: access_token.id,
          expires_in: AccessToken.expires_in,
          refresh_token: refresh_token.id,
          scope: refresh_token.scope,
          token_type: "bearer"
        }
        [200, {'Content-Type' => 'application/json'}, response.to_json]
      end
    end

    def password_grant_type(client, granted_scope)
      if resource_owner = ResourceOwner.find_by_username_and_password!(params[:username], params[:password])
        attributes = { client_id: client.id, scope: granted_scope, resource_owner_id: resource_owner.id }
        access_token = AccessToken.create! attributes
        refresh_token = RefreshToken.create! attributes
        response = {
          access_token: access_token.id,
          expires_in: AccessToken.expires_in,
          refresh_token: refresh_token.id,
          scope: granted_scope,
          token_type: "bearer"
        }
        [200, {'Content-Type' => 'application/json'}, response.to_json]
      end
    end

    def client_credentials_grant_type(client, granted_scope)
      access_token = AccessToken.create!({client_id: client.id})
      response = {
          access_token: access_token.id,
          expires_in: AccessToken.expires_in,
          scope: granted_scope,
          token_type: "bearer"
        }
      [200, {'Content-Type' => 'application/json'}, response.to_json]
    end

    def response(env)
      client = Client.find! params[:client_id]
      client.validate_secret! params[:client_secret]
      if params[:scope]
        requested_scopes = params[:scope].split
        granted_scope = client.authorize_scope(requested_scopes)
      else
        granted_scope = []
      end
      send "#{params[:grant_type]}_grant_type", client, granted_scope
    end
  end
end
