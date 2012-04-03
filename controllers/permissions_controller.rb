module PermissionsController
  def self.included(base)
    base.get '/permissions', Show
  end

  class Show < Goliath::API
    def access_token
      @access_token ||= AccessToken.find(env['HTTP_AUTHENTICATION'].match(/Bearer\s+(\w+)/i)[1])
    end

    def links
      {
        self: "/permissions"
      }
    end

    def response(env)
      response = {
        _links: links,
        scope: access_token.scope
      }
      [200, {'Content-Type' => 'application/JSON'}, response.to_json]
    end
  end
end
