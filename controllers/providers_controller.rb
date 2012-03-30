module ProvidersController
  def self.included(base)
    base.get 'providers/:provider', Authorization
    base.get '/:provider/callback', Callback
  end

  module CommonValidations
    def self.included(base)
      base.use Goliath::Rack::Validation::RequiredValue, {
        :key => :provider,
        :values => Provider.all.map(&:name)
      }

      %w{client_id redirect_uri}.each do |attribute|
        base.use Goliath::Rack::Validation::RequiredParam, {
          :key => attribute,
          :message => 'query parameter missing.'
        }
      end
    end
  end

  class Authorization < Goliath::API
    include CommonValidations

    def response(env)
      provider = Provider[params[:provider]]
      redirect_url = provider.authentication_url(env)
      [302, {'Location' => redirect_url}]
    end
  end # Authorization

  class Callback < Goliath::API
    include CommonValidations

    def response(env)
      if provider = Provider[params[:provider]]
        uid = provider.uid(env)
        if user_id = REDIS.HGET(provider.name, uid)
          user = User.find(user_id)
        else
          user = User.new
          user.save
          REDIS.HSET provider.name, uid, user.id
        end
        code = Code.new({user_id: user.id, client_id: 1})
        code.save
        query = Rack::Utils.build_query({code: code.id})
        redirect_url = params[:redirect_uri] + '?' + query
        [302, {'Location' => redirect_url}]
      end
    end
  end # Callback
end # ProvidersController
