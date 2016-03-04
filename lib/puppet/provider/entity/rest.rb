require_relative '../rest.rb'

Puppet::Type.type(:entity).provide(:rest, :parent => Puppet::Provider::RestClient) do

  mk_resource_methods

  def self.instances
    entity_resources = []

    begin
      response = rest_get '/'
      if not response.nil?
        response.each do |entity_json|
          entity_resource = {
            :ensure     => :present,
            :id         => entity_json['id'],
            :name       => entity_json['name'],
            :attributes => entity_json['attributes']
          }

          entity_resources << new(entity_resource)
        end
      end
    rescue Exception
      raise Puppet::Error, "Failed to query endpoint for entity list: #{$!}"
    end
    
    return entity_resources
  end

  def create
    begin
    rescue Exception
      raise Puppet::Error, "Failed to create entity #{@resource[:name]}: #{$!}"
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    begin
    rescue Exception
      raise Puppet::Error, "Failed to delete entity #{@resource[:name]}: #{$!}"
    end
  end

end

