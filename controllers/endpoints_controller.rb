module EndpointsController
  def self.included(base)
    base.get '/', Show
  end

  class Show < Goliath::API
    def response(env)
      headers = {
        'Content-Type' => 'application/vnd.collection+json',
        'Cache-Control' => 'max-age=3600, must-revalidate'
      }

      response = CollectionJSON.generate_for('/') do |builder|
        builder.add_link '/resource_owner', 'resource_owner'
        builder.add_link '/authorize', 'oauth2_authorize'
        builder.add_link '/token', 'oauth2_token'
        builder.add_link '/providers', 'providers' if Provider.all.count >= 1
      end

      [200, headers, response.to_json]
    end
  end
end
