require 'json'
require 'hiredis'
require 'em-synchrony'
require "em-synchrony/em-http"
require 'redis/connection/synchrony'
require 'redis/scripted'
require 'goliath'
require 'uri'
require 'logger'

require './models/base_model'
require './models/user'

require './lib/authorization'
require './lib/endpoints'
require './lib/provider'
require './lib/token'
require './lib/users'

if ENV['REDISTOGO_URL']
  uri = URI.parse(ENV["REDISTOGO_URL"])
  REDIS = Redis.new({
    host:     uri.host,
    port:     uri.port,
    password: uri.password
  })
else
  REDIS = Redis::Scripted.new(scripts_path: "./lib/scripts")
end

def base_url
  'http://' + env["HTTP_HOST"]
end

def providers_from_env
  ENV['AUTH_PROVIDERS'].split(/[\s,]+/) if ENV['AUTH_PROVIDERS']
end

def providers
  @providers ||= providers_from_env || []
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
