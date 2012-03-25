require 'json'
require 'hiredis'
require 'em-synchrony'
require "em-synchrony/em-http"
require 'redis/connection/synchrony'
require 'redis'
require 'goliath'
require 'uri'
require 'logger'

require './models/redis_model'
%w{models lib controllers}.each do |dir|
  Dir["./#{dir}/*.rb"].each {|file| require(file.gsub(/\.rb/, '')) }
end

if ENV['REDISTOGO_URL']
  uri = URI.parse(ENV["REDISTOGO_URL"])
  REDIS = Redis.new({
    host:     uri.host,
    port:     uri.port,
    password: uri.password
  })
else
end

def base_url
  'http://' + env["HTTP_HOST"]
end

def providers_from_env
  ENV['AUTH_PROVIDERS'].split(/[\s,]+/) if ENV['AUTH_PROVIDERS']
end

def providers
  @providers ||= providers_from_env || []
  REDIS = Redis.new
end

class AuthenticationService < Goliath::API
  use Goliath::Rack::Params

  include AuthorizationsController
  include EndpointsController
  include ProvidersController
  include UsersController
  include TokensController
  
  def response(env)
    error = {error: 'Invalid route.'}
    [404, {'Content-Type' => 'application/JSON'}, error.to_json]
  end
end
