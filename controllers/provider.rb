require_relative './mixins/code_builder'
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
        redirect = ProviderStrategies::Facebook.new(env)._authentication_url
        [301, {'Location' => redirect}]
      else
        unknown_provider
      end
    end
  end

  class Callback < Goliath::API
    include CodeBuilder

    def response(env)
      external_user = ProviderStrategies::Facebook.new(env)._user
      user = User.find_or_create_by_provider_type_and_provider_uid(\
        params[:provider], external_user.id)
      if user
        code = build_code(user, nil)
        query = Rack::Utils.build_query({code: code})
        redirect_url = params[:redirect_uri] + '?' + query
        [200, {'Content-Type' => 'application/JSON'}, redirect_url]
      else
        error = {error: "Can't get user."}
        [400, {'Content-Type' => 'application/JSON'}, error.to_json]
      end
    end
  end
end
