require 'uri'

class Client < RedisModel
  namespace :client
  id_type :sequential

  def validate_url(value)
    URI.parse(value).host == URI.parse(redirect_uri).host
  end

  def validate_url!(value, status = 400, msg = "Invalid redirect_uri for given client.")
    validate_url(value) or raise Goliath::Validation::Error.new(status, msg)
  end

  def validate_secret(value)
    value == secret
  end

  def validate_secret!(value, status = 400, msg = "Invalid client_secret.")
    validate_secret(value) or raise Goliath::Validation::Error.new(status, msg)
  end
end
