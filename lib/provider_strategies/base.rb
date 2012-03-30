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
      'http://' + env["HTTP_HOST"] + "/providers/#{params[:provider]}/callback?" + redirect_query
    end
  end # Base
end # ProviderStrategies
