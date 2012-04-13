module ResourceOwnersController
  def self.included(base)
    base.get '/~', Show
    base.put '/~', Update
    base.post '/~', Create
  end

  module Authenticatable
    def access_token
      @access_token ||= AccessToken.find(env['HTTP_AUTHENTICATION'].match(/Bearer\s+(\w+)/i)[1])
    end

    def resource_owner
      if access_token
        resource_owner_id = access_token.resource_owner_id!
        @resource_owner ||= ResourceOwner.find!(resource_owner_id)
      end
    end
  end

  class Show < Goliath::API
    include HATEOAS
    include Authenticatable

    def response(env)
      if resource_owner
        add_item '/~' do |item|
          item.add_data 'uid', resource_owner.id
          item.add_data 'name', resource_owner.name
          item.add_data 'company_id', resource_owner.company_id
        end
        generate_response '/~'
      else
        message = "Invalid or expired access_token."
        raise Goliath::Validation::Error.new(400, message)
      end
    end
  end

  class Update < Goliath::API
    include Authenticatable

    def update_tokens
      json = resource_owner.to_json only:
        [:authenticatable_id, :authenticatable_type]
      REDIS.set "refresh_token:#{refresh_token}", json
      REDIS.set "access_token:#{access_token}", json
      json
    end

    def refresh_token
      REDIS.get "access_token:#{access_token}:refresh_token"
    end
    
    def response(env)
      resource_owner.update_attributes! params
      [200, {'Content-Type' => 'application/JSON'}, update_tokens]
    end
  end

  class Create < Goliath::API
    %w{client_id redirect_uri}.each do |attribute|
      use Goliath::Rack::Validation::RequiredParam, {
        :key => attribute,
        :message => 'parameter missing.'
      }
    end

    def resource_owner_params
      params.select do |k,v|
        !%w{client_id redirect_uri}.include? k
      end
    end

    def response(env)
      if client = Client.find(params[:client_id])
        unless client.valid_url(params[:redirect_uri])
          message = "Invalid redirect_uri for given client."
          raise Goliath::Validation::Error.new(400, message)
        end
        resource_owner = ResourceOwner.new(resource_owner_params)
        resource_owner.save
        code = Code.new({resource_owner_id: resource_owner.id, client_id: client.id})
        code.save
        query = Rack::Utils.build_query({code: code.id})
        redirect_url = params[:redirect_uri] + '?' + query
        [301, {'Location' => redirect_url}]
      else
        message = "Invalid client_id."
        raise Goliath::Validation::Error.new(400, message)
      end
    end
  end
end
