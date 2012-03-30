require 'oauth'
require 'oauth/client/em_http'
require_relative './base'

module ProviderStrategies
  class Linkedin < ProviderStrategies::Base
    class User
      attr_accessor :id

      def initialize(args)
        args.each do |k,v|
          send "#{k}=", v if respond_to? "#{k}="
        end
      end
    end # User

    def valid?
      params[:provider] == 'linkedin' &&
      ENV['LINKEDIN_ID'] &&
      ENV['LINKEDIN_SECRET']
    end

    def consumer
      consumer_options = {
        site: "https://www.linkedin.com",
        request_token_path: "/uas/oauth/requestToken",
        access_token_path: "/uas/oauth/accessToken",
        authorize_path: "/uas/oauth/authenticate"
      }
      OAuth::Consumer.new(ENV['LINKEDIN_ID'], ENV['LINKEDIN_SECRET'], consumer_options)
    end

    def authentication_url
      temp_id = SecureRandom.hex(8)
      _redirect_uri = "#{redirect_uri}&temp_store=#{temp_id}"
      request_token = consumer.get_request_token(:oauth_callback => _redirect_uri)
      auth_url = request_token.authorize_url(:oauth_callback => _redirect_uri)
      temp_store = TempOauthStore.new({
        :token => request_token.token,
        :secret => request_token.secret
      }, temp_id)
      temp_store.save

      auth_url
    end

    def fetch_user
      temp_store = TempOauthStore.find(params[:temp_store])
      request_token = OAuth::RequestToken.new(consumer, temp_store.token, temp_store.secret)
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      json = access_token.get("/v1/people/~:(id)", 'x-li-format' => 'json').body
      JSON.parse(json)
    end

    def user
      @user ||= User.new(fetch_user)
    end

    def uid
      user.id
    end
  end # Linkedin
end # ProviderStrategies
