module EndpointsController
  def self.included(base)
    base.get '/', Show
  end

  class Show < Goliath::API
    include HATEOAS

    def response(env)
      add_header 'Cache-Control', 'max-age=3600, must-revalidate'
      add_link 'resource_owner', '/~'
      add_link 'oauth2_authorize', '/authorize'
      add_link 'oauth2_token', '/token'
      add_link 'providers', '/providers' if Provider.all.count >= 1
      generate_response '/'
    end
  end
end
