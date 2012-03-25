require_relative './base'

module ProviderStrategies
  class Facebook < ProviderStrategies::Base
    class Token
      attr_accessor :access_token, :expires

      def initialize(token_string)
        token_string.split('&').inject({}) do |token, str|
          k, v = str.split('=')
          send "#{k}=", v if respond_to? "#{k}="
        end
      end
    end # Token

    class User
      attr_accessor :id

      def initialize(args)
        args.each do |k,v|
          send "#{k}=", v if respond_to? "#{k}="
        end
      end
    end # User

    def valid?
      params[:provider] == 'facebook' &&
      ENV['FACEBOOK_ID'] &&
      ENV['FACEBOOK_SECRET']
    end

    def authentication_url
      "https://www.facebook.com/dialog/oauth?" + build_query({
        client_id: ENV['FACEBOOK_ID'],
        redirect_uri: redirect_uri
      })
    end

    def graph_request(path)
      EventMachine::HttpRequest.new("https://graph.facebook.com#{path}")
    end

    def fetch_token
      request = graph_request('/oauth/access_token').get(query: {
        :client_id      => ENV['FACEBOOK_ID'],
        :client_secret  => ENV['FACEBOOK_SECRET'],
        :code           => params[:code],
        :redirect_uri   => redirect_uri
      }).response
    end

    def token
      @token ||= Token.new(fetch_token)
    end

    def fetch_user
      request = graph_request('/me').get(query: {
        access_token: token.access_token
      })
      JSON.parse request.response
    end

    def user
      @user ||= User.new(fetch_user)
    end

    def uid
      user.id
    end
  end # Facebook
end # ProviderStrategies
