module UsersController
  def self.included(base)
    base.get '/user', Show
    base.put '/user', Update
    base.post '/users', Create
  end

  module Authenticatable
    def access_token
      @token ||= env['HTTP_AUTHENTICATION'].match(/Bearer\s+(\w+)/i)[1]
    end

    def authenticatable
      @authenticatable ||= REDIS.get "access_token:#{access_token}"
    end

    def user
      @user ||= _user
    end

    private
    
    def _user
      User.find(REDIS.get("access_token:#{access_token}:user_id"))
    end
  end

  class Show < Goliath::API
    include Authenticatable

    def response(env)
      [200, {'Content-Type' => 'application/JSON'}, authenticatable]
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
    def forwardable_params
      params.select do |k,v|
        !%w{email password password_confirmation client_id redirect_uri}\
          .include? k
      end
    end

    def response(env)
      user = User.create!(params)
      code = build_code(user, nil)
      query = Rack::Utils.build_query \
        forwardable_params.merge({code: code})
      redirect_url = params[:redirect_uri] + '?' + query
      [200, {'Content-Type' => 'application/JSON'}, redirect_url]
    end
  end
end
