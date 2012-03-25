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
require './models/user'

require './controllers/authorization'
require './controllers/endpoints'
require './controllers/provider'
require './controllers/token'
require './controllers/users'

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

  include Authorization
  include Users
  include Token
  
  include Directory
  include Provider
  
  def response(env)
    error = {error: 'Invalid route.'}
    [404, {'Content-Type' => 'application/JSON'}, error.to_json]
  end
end
