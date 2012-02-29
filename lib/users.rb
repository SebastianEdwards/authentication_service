module Users
  def self.included(base)
    base.get '/users/:id', Show
    base.post '/users', Create do
      use Goliath::Rack::Validation::RequiredParam, :key => 'client_id'
      use Goliath::Rack::Validation::RequiredParam, :key => 'redirect_uri'
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
    def response(env)
      user = User.new(params)
      user.save!
      forwardable_params = params.select do |k,v|
        !%w{email password password_confirmation client_id redirect_uri}\
          .include? k
      end
      [200, {'Content-Type' => 'application/JSON'}, forwardable_params.to_json]
    end
  end
end
