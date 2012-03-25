module EndpointsController
  def self.included(base)
    base.get '/', Endpoints
  end

  class Endpoints < Goliath::API
    def endpoint_urls
      endpoints = {}
      endpoints[:authorize_url] = '/authorize'
      endpoints[:token_url] = '/token'
      Provider.all.each do |provider|
        endpoints[provider.name + '_url'] = provider.endpoint_url
      end
      endpoints
    end

    def response(env)
      [200, {'Content-Type' => 'application/JSON'}, endpoint_urls.to_json]
    end
  end
end
