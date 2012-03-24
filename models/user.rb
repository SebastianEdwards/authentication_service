class User < RedisModel
  namespace 'user'

  def valid?
    valid_via_email? || valid_via_provider?
  end

  private
  def valid_via_email?
    attributes.has_key?('email') && attributes.has_key?('password_digest')
  end

  def valid_via_provider?
    attributes.has_key?('provider_uid') && attributes.has_key?('provider_type')
  end
end
