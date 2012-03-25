class User < RedisModel
  namespace :user
  id_type :sequential
end
