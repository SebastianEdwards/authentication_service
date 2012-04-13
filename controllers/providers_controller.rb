module ProvidersController
  def self.included(base)
    base.get '/providers/:provider/callback', Callback
    base.get '/providers/:provider', Authorization
    base.get '/providers', Show
  end

  module CommonValidations
    def self.included(base)
      base.use Goliath::Rack::Validation::RequiredValue, {
        :key => :provider,
        :values => Provider.all.map(&:name)
      }

      %w{client_id redirect_uri}.each do |attribute|
        base.use Goliath::Rack::Validation::RequiredParam, {
          :key => attribute,
          :message => 'query parameter missing.'
        }
      end
    end
  end

  class Show < Goliath::API
    include HATEOAS

    def response(env)
      add_header 'Cache-Control', 'max-age=3600, must-revalidate'
      add_link 'self', '/providers'
      Provider.all.each do |provider|
        add_link "/auth/provider/#{provider.name}", provider.endpoint_url, {:prompt => provider.prompt}
      end
      generate_response
    end
  end

  class Authorization < Goliath::API
    include CommonValidations

    def response(env)
      client = Client.find!(params[:client_id])
      client.validate_url!(params[:redirect_uri])
      provider = Provider[params[:provider]]
      redirect_url = provider.authentication_url(env)
      [302, {'Location' => redirect_url}]
    end
  end # Authorization

  class Callback < Goliath::API
    include CommonValidations

    def response(env)
      client = Client.find!(params[:client_id])
      client.validate_url!(params[:redirect_uri])
      provider = Provider[params[:provider]]
      provider_uid = provider.uid(env)
      unless resource_owner = ResourceOwner.find_by_provider_and_uid(provider.name, provider_uid)
        resource_owner = ResourceOwner.create!({}, 400, "Error creating resource owner.")
        resource_owner.associate_with_provider!(provider.name, provider_uid)
      end
      code = Code.create!({resource_owner_id: resource_owner.id, client_id: client.id})
      query = Rack::Utils.build_query({code: code.id})
      redirect_url = params[:redirect_uri] + '?' + query
      [302, {'Location' => redirect_url}]
    end
  end # Callback
end # ProvidersController
