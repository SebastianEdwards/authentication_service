module EndpointsController
  def self.included(base)
    base.get '/', Show
  end

  class Show < Goliath::API
    include HATEOAS

    def response(env)
      add_link '/oauth2/authorize', '/authorize'
      add_link '/oauth2/token', '/token'
      add_link '/auth/providers', '/providers' if Provider.all.count >= 1
      generate_response
    end
  end
end
