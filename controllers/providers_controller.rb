# require_relative './mixins/code_builder'

module ProvidersController
  def self.included(base)
    base.get 'providers/:provider', Authorization
    #  do
    #   use Goliath::Rack::Validation::RequiredParam, :key => 'client_id'
    #   use Goliath::Rack::Validation::RequiredParam, :key => 'redirect_uri'
    # end
    base.get '/:provider/callback', Callback
  end

  def unknown_provider
    error = {error: 'Unknown provider.'}
    [400, {'Content-Type' => 'application/JSON'}, error.to_json]
  end

  class Authorization < Goliath::API
    def response(env)
      if provider = Provider[params[:provider]]
        redirect = provider.authentication_url(env)
        [301, {'Location' => redirect}]
      else
        unknown_provider
      end
    end
  end # Authorization

  class Callback < Goliath::API
    def response(env)
      if provider = Provider[params[:provider]]
        uid = provider.uid(env)
        user_id = REDIS.HGET(provider.name, uid)
        user = (user_id ? User.find(user_id) : (u = User.new; u.save; u))
        code = Code.new({user_id: user.id, client_id: 1})
        code.save
        query = Rack::Utils.build_query({code: code.id})
        redirect_url = params[:redirect_uri] + '?' + query
        [200, {'Content-Type' => 'application/JSON'}, redirect_url]
      end
    end
  end # Callback
end # ProvidersController
