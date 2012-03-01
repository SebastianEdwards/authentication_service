class User < ActiveRecord::Base
  has_many :authorizations
  has_secure_password
  attr_accessible :email,
                  :password,
                  :provider_uid,
                  :provider_type,
                  :authenticatable_id,
                  :authenticatable_type

  validates :email, :password, presence:
    {unless: -> {provider_uid && provider_type}}
  validates :provider_uid, :provider_type, presence:
    {unless: -> {email && password || password_digest}}
end
