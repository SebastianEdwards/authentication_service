module UsersController
  def self.included(base)
    base.get '/users', Show
    base.put '/users', Update
    base.post '/users', Create
  end

  module Authenticatable
    def access_token
      @access_token ||= AccessToken.find(env['HTTP_AUTHENTICATION'].match(/Bearer\s+(\w+)/i)[1])
    end

    def user
      @user ||= User.find(access_token.user_id) if access_token
    end
  end

  class Show < Goliath::API
    include Authenticatable

    def response(env)
      if user
        [200, {'Content-Type' => 'application/JSON'}, user.to_json]
      else
        message = "Invalid or expired access_token."
        raise Goliath::Validation::Error.new(400, message)
      end
    end
  end

  class Update < Goliath::API
    include Authenticatable

    def update_tokens
      json = user.to_json only:
        [:authenticatable_id, :authenticatable_type]
      REDIS.set "refresh_token:#{refresh_token}", json
      REDIS.set "access_token:#{access_token}", json
      json
    end

    def refresh_token
      REDIS.get "access_token:#{access_token}:refresh_token"
    end
    
    def response(env)
      user.update_attributes! params
      [200, {'Content-Type' => 'application/JSON'}, update_tokens]
    end
  end

  class Create < Goliath::API
    def storable_params
      params.select do |k,v|
        !%w{password password_confirmation client_id redirect_uri}\
          .include? k
      end
    end

    def response(env)
      user = User.new(storable_params)
      user.save
      code = Code.new({user_id: user.id, client_id: 1})
      code.save
      query = Rack::Utils.build_query({code: code.id})
      redirect_url = params[:redirect_uri] + '?' + query
      [301, {'Location' => redirect_url}]
    end
  end
end
