module ResourceOwnersController
  def self.included(base)
    base.get '/resource_owner/:resource_owner_id', Show
    base.get '/resource_owner/:resource_owner_id/:resource', ResourceShow
    base.put '/resource_owner/:resource_owner_id', Update
    base.post '/resource_owner', Create
  end

  module Authenticatable
    def access_token
      if env['HTTP_AUTHENTICATION']
        @access_token ||= AccessToken.find(env['HTTP_AUTHENTICATION'].match(/Bearer\s+(\w+)/i)[1])
      end
    end

    def allowed_resource?(resource)
      access_token.scope.include?("manage_#{resource}") ||
      access_token.scope.include?("read_#{resource}")
    end

    def resource_owner
      if access_token
        token_resource_owner_id = access_token.resource_owner_id!
        if params[:resource_owner_id] == '~'
          resource_owner_id = token_resource_owner_id
        elsif params[:resource_owner_id] == token_resource_owner_id
          resource_owner_id = params[:resource_owner_id]
        else
          message = "Token not authorized to access this resource owner."
          raise Goliath::Validation::Error.new(400, message)
        end
        @resource_owner ||= ResourceOwner.find!(resource_owner_id)
      end
    end

    def resource_owner!(status = 400, msg = "Invalid or expired access token.")
      resource_owner or raise Goliath::Validation::Error.new(status, msg)
    end

    def allowed_resource!(resource, status = 400, msg = "Access token not allowed access to this resource.")
      allowed_resource?(resource) or raise Goliath::Validation::Error.new(status, msg)
    end
  end

  class Show < Goliath::API
    include Authenticatable

    def response(env)
      if resource_owner!
        headers = { 'Content-Type' => 'application/vnd.collection+json' }

        response = CollectionJSON.generate_for("/resource_owner/#{resource_owner.id}") do |builder|
          builder.add_item "/resource_owner/#{resource_owner.id}" do |item|
            item.add_data 'uid', resource_owner.id.to_i
            item.add_data 'name', resource_owner.name
          end
          resource_owner.resources.each do |resource_name, _|
            if allowed_resource?(resource_name)
              builder.add_link "/resource_owner/#{resource_owner.id}/#{resource_name}", resource_name
            end
          end
        end
        
        [200, headers, response.to_json]
      end
    end
  end

  class ResourceShow < Goliath::API
    include Authenticatable

    def response(env)
      headers = { 'Content-Type' => 'application/vnd.collection+json' }
      if resource_owner! && allowed_resource!(params[:resource])
        href = "/resource_owner/#{resource_owner.id}/#{params[:resource]}"
        response = CollectionJSON.generate_for(href) do |builder|
          builder.add_link "/resource_owner/#{resource_owner.id}", 'resource_owner'
          resource_owner.resources[params[:resource]].each do |company_href|
            builder.add_item company_href
          end
          builder.set_template do |template|
            template.add_data 'href', '', 'Resource URI'
          end
        end

        [200, headers, response.to_json]
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
