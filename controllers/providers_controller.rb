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
    # include CodeBuilder

    def response(env)
      if provider = Provider[params[:provider]]
        uid = provider.uid(env)
        [200, {'Content-Type' => 'application/JSON'}, uid]
      #   if user
      #     code = build_code(user, nil)
      #     query = Rack::Utils.build_query({code: code})
      #     redirect_url = params[:redirect_uri] + '?' + query
      #     [200, {'Content-Type' => 'application/JSON'}, redirect_url]
      #   else
      #     error = {error: "Can't get user."}
      #     [400, {'Content-Type' => 'application/JSON'}, error.to_json]
      #   end
      end
    end
  end # Callback
end # ProvidersController
