require_relative './provider_strategies/facebook'

module Provider
  def self.included(base)
    base.get '/:provider', Authorization do
      use Goliath::Rack::Validation::RequiredParam, :key => 'client_id'
      use Goliath::Rack::Validation::RequiredParam, :key => 'redirect_uri'
    end
    base.get '/:provider/callback', Callback
  end

  def unknown_provider
    error = {error: 'Unknown provider.'}
    [400, {'Content-Type' => 'application/JSON'}, error.to_json]
  end

  class Authorization < Goliath::API
    def response(env)
      if %w(facebook twitter).include? params[:provider]
        redirect = ProviderStrategies::Facebook::Authorization.new(env).call
        [301, {'Location' => redirect}]
      else
        unknown_provider
      end
    end
  end

  class Callback < Goliath::API
    def response(env)
      user = ProviderStrategies::Facebook::Callback.new(env).call
      if user
        response = {
          "#{params[:provider]}_uid" => user.id
        }
        [200, {'Content-Type' => 'application/JSON'}, response.to_json]
      else
        error = {error: "Can't get user."}
        [400, {'Content-Type' => 'application/JSON'}, error.to_json]
      end
    end
  end
end
