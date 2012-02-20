module ProviderStrategies
  class Base
    attr_reader :env, :params

    def initialize(env)
      @env = env
      @params = env.params
    end

    def valid?; true; end

    def build_query(hash)
      Rack::Utils.build_query(hash)
    end

    def redirect_uri
      query = {
        redirect_uri: params[:redirect_uri],
        client_id: params[:client_id]
      }
      redirect_query = build_query(query)
      base_url + "/#{params[:provider]}/callback?" + redirect_query
    end

    def _authentication_url
      self.authentication_url if valid?
    end

    def _user
      self.user if valid?
    end
  end # Base
end # ProviderStrategies
