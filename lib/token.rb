module Token
  def self.included(base)
    base.get '/token', Create
  end

  class Create < Goliath::API
    def response(env)
      [200, {'Content-Type' => 'application/JSON'}, params.to_json]
    end
  end
end
