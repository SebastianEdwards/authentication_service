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

    def clean_redirect_uri(redirect_uri)
      URI.parse(redirect_uri).tap do |uri|
        uri.query.gsub! /code=\w+/, '' if uri.query
      end.to_s
    end

    def redirect_uri
      query = {
        redirect_uri: clean_redirect_uri(params[:redirect_uri]),
        client_id: params[:client_id],
        scope: params[:scope]
      }
      redirect_query = build_query(query)
      'http://' + env["HTTP_HOST"] + "/providers/#{params[:provider]}/callback?" + redirect_query
    end
  end # Base
end # ProviderStrategies
