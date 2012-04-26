module ResourceOwnersController
  def self.included(base)
    base.get '/resource_owners/:resource_owner_id', Show
    base.get '/resource_owners/:resource_owner_id/:resource', ResourceShow
    base.put '/resource_owners/:resource_owner_id', Update
    base.get '/resource_owners', Index
    base.post '/resource_owners', Create
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
        @resource_owner ||= ResourceOwner.find!(token_resource_owner_id)
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
        headers = {
          'Content-Type' => 'application/vnd.collection+json',
          'Cache-Control' => 'max-age=5, must-revalidate',
          'Vary' => 'Authentication'
        }

        response = CollectionJSON.generate_for("/resource_owners/#{resource_owner.id}") do |builder|
          builder.add_item "/resource_owners/#{resource_owner.id}" do |item|
            item.add_data 'uid', value: resource_owner.id.to_i
            item.add_data 'name', value: resource_owner.name
          end
          resource_owner.resources.each do |resource_name, _|
            if allowed_resource?(resource_name)
              builder.add_link "/resource_owners/#{resource_owner.id}/#{resource_name}", resource_name
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
        href = "/resource_owners/#{resource_owner.id}/#{params[:resource]}"
        response = CollectionJSON.generate_for(href) do |builder|
          builder.add_link "/resource_owners/#{resource_owner.id}", 'resource_owner'
          builder.add_link resource_owner.resources[params[:resource]].first, 'first'
          resource_owner.resources[params[:resource]].each do |company_href|
            builder.add_item company_href
          end
          builder.set_template do |template|
            template.add_data 'href', prompt: 'Resource URI'
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

  class Index < Goliath::API
    include Authenticatable

    def response(env)
      headers = {
        'Content-Type' => 'application/vnd.collection+json',
        'Cache-Control' => 'max-age=3600, must-revalidate',
        'Vary' => 'Authentication'
      }

      response = CollectionJSON.generate_for('/resource_owners') do |builder|
        builder.add_link("/resource_owners/#{resource_owner.id}", "current") if resource_owner
        builder.set_template do |template|
          template.add_data 'username', prompt: 'Email'
          template.add_data 'password', prompt: 'Password'
          template.add_data 'client_id', prompt: 'Client ID'
          template.add_data 'redirect_uri', prompt: 'Redirect URI'
        end
      end

      [200, headers, response.to_json]
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
        client.validate_url(params[:redirect_uri])
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
