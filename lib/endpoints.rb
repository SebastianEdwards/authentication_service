module Directory
  def self.included(base)
    base.get '/', Endpoints
  end

  class Endpoints < Goliath::API
    def endpoint_urls
      endpoints = {}
      endpoints[:authorize_url] = base_url + '/authorize'
      endpoints[:token_url] = base_url + '/token'
      providers.each {|provider| endpoints[provider + '_url'] = base_url + "/#{provider}"}
      endpoints
    end

    def response(env)
      [200, {'Content-Type' => 'application/JSON'}, endpoint_urls.to_json]
    end
  end
end
