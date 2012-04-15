require 'json'
require 'hiredis'
require 'em-synchrony'
require "em-synchrony/em-http"
require 'redis'
require 'redis/connection/synchrony'
require 'collection-json'
require 'goliath'
require 'uri'
require 'logger'

require './models/redis_model'
%w{models lib controllers}.each do |dir|
  Dir["./#{dir}/*.rb"].each {|file| require(file.gsub(/\.rb/, '')) }
end

if ENV['REDISTOGO_URL']
  REDIS = EM::Synchrony::ConnectionPool.new(size: 2) do
    uri = URI.parse(ENV["REDISTOGO_URL"])
    Redis.new({
      host:     uri.host,
      port:     uri.port,
      password: uri.password
    })
  end
else
  REDIS = EM::Synchrony::ConnectionPool.new(size: 2) { Redis.new }
end

class AuthenticationService < Goliath::API
  use Goliath::Rack::Params

  include AuthorizationsController
  include EndpointsController
  include PermissionsController
  include ProvidersController
  include ResourceOwnersController
  include TokensController
  
  def response(env)
    error = {error: 'Invalid route.'}
    [404, {'Content-Type' => 'application/JSON'}, error.to_json]
  end
end

module Goliath
  module Rack
    module Validator
      def validation_error(status_code, msg, headers={})
        headers.delete('Content-Length')
        unless headers.has_key?('Content-Type')
          headers.merge!({'Content-Type' => 'application/JSON'})
        end
        msg = {error: msg} if msg.class == String
        [status_code, headers, msg.to_json]
      end
    end
  end
end
