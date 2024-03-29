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
    def response(env)
      headers = {
        'Content-Type' => 'application/vnd.collection+json;type=providers',
        'Cache-Control' => 'max-age=3600, must-revalidate'
      }

      response = CollectionJSON.generate_for('/providers') do |builder|
        builder.add_link 'auth:providers', 'profile'
        Provider.all.each do |provider|
          builder.add_query provider.endpoint_url, provider.name, prompt: provider.prompt do |query|
            query.add_data 'client_id', prompt: 'Client ID'
            query.add_data 'redirect_uri', prompt: 'Post-auth Redirect URI'
            query.add_data 'scope', prompt: 'Scope to grant successful access token.'
          end
        end
      end

      [200, headers, response.to_json]
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

    def redirect_uri(code_id)
      query = Rack::Utils.build_query({code: code_id})
      URI.parse(params[:redirect_uri]).tap do |uri|
        if uri.query && uri.query != ''
          uri.query += "&#{query}"
        else
          uri.query = query
        end
      end.to_s
    end

    def response(env)
      client = Client.find!(params[:client_id])
      client.validate_url!(params[:redirect_uri])
      if params[:scope]
        requested_scopes = params[:scope].split
        granted_scope = client.authorize_scope(requested_scopes)
      else
        granted_scope = []
      end
      provider = Provider[params[:provider]]
      provider_uid = provider.uid(env)
      unless resource_owner = ResourceOwner.find_by_provider_and_uid(provider.name, provider_uid)
        resource_owner = ResourceOwner.create!({}, 400, "Error creating resource owner.")
        resource_owner.associate_with_provider!(provider.name, provider_uid)
      end
      code = Code.create!({resource_owner_id: resource_owner.id, client_id: client.id, scope: granted_scope})
      [302, {'Location' => redirect_uri(code.id)}]
    end
  end # Callback
end # ProvidersController
