module AuthorizationsController
  def self.included(base)
    base.get '/authorize', New do
      use Goliath::Rack::Validation::RequiredParam, :key => 'client_id'
    end
    base.post '/authorize', Create
  end

  class New < Goliath::API
    def response(env)
      [200, {'Content-Type' => 'application/JSON'}]
    end
  end

  class Create < Goliath::API
    def response(env)
      [200, {'Content-Type' => 'application/JSON'}]
    end
  end
end
