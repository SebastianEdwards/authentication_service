module Users
  def self.included(base)
    base.get '/users/:id', Show
    base.post '/users', Create
    end
  end

  class Show < Goliath::API
    def response(env)
      user = User.find params[:id]
      user_json = user.to_json only:
        [:authenticatable_id, :authenticatable_type]
      [200, {'Content-Type' => 'application/JSON'}, user_json]
    end
  end

  class Create < Goliath::API
    def build_code
      code = SecureRandom.hex(8)
      REDIS.set "code:#{code}",
        {user_id: @user.id, client_id: 1}.to_json
      code
    end

    def forwardable_params
      params.select do |k,v|
        !%w{email password password_confirmation client_id redirect_uri}\
          .include? k
      end
    end

    def response(env)
      @user = User.create!(params)
      query = Rack::Utils.build_query \
        forwardable_params.merge({code: build_code})
      redirect_url = params[:redirect_uri] + '?' + query
      [200, {'Content-Type' => 'application/JSON'}, redirect_url]
    end
  end
end
