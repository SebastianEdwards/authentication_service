module ProviderStrategies
  module Base
    module CommonMethods
      attr_accessor :env, :params

      def initialize(_env)
        self.env = _env
        self.params = _env['params']
      end

      def valid?
        false
      end

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
    end

    class Authorization
      include CommonMethods

      def call
        self.redirect_to if valid?
      end
    end

    class Callback
      include CommonMethods

      def call
        self.user if valid?
      end
    end
  end
end
