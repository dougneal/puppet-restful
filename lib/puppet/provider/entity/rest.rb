# We depend on the REST client code in the rest.rb file in the parent directory.
# If you have several types and providers in your module that share code, this is
# a good pattern to follow to save code repetition.
require_relative '../rest.rb'

# We are calling Puppet's type API to let it know that the block that follows contains
# a provider for the 'entity' type. Behind the scenes Puppet is using Ruby metaprogramming
# to generate a class called Puppet::Type::Entity::ProviderRest.
#
# We are also specifying that Puppet::Provider::RestClient is the class we want to
# inherit from. This makes the REST client methods in ../rest.rb our own.
# In turn, this class will be a subclass of Puppet::Provider.
Puppet::Type.type(:entity).provide(:rest, :parent => Puppet::Provider::RestClient) do

  # It's good practice to call mk_resource_methods in a provider block - this generates
  # accessor methods for all properties supported by this type.
  # This is a method of the Puppet::Provider class.
  mk_resource_methods

  # Each of these 'def' blocks is a method declaration. The methods beginning with 'self.'
  # have a special significance: this indicates to Ruby that this is a class method rather
  # than an instance method. That is, it operates on the class itself rather than a
  # given object.

  # self.instances is called by Puppet during its discovery phase, i.e. when it is
  # enumerating the resources of this type that exist on the target system already.
  # Hopefully this illustrates why this is a class method: it's a method that generates
  # instances (objects).
  def self.instances

    # We're going to return an array of resource objects, so get it ready
    entity_providers = []

    begin
      # Call GET at the root of the API to fetch a document containing all resources.
      # (rest_get is one of the REST methods in our Puppet::Provider::RestClient helper class)
      response = rest_get '/'

      if not response.nil?
        response.each do |entity_json|
          # Translate what we found in the JSON object into a hash that resembles a
          # Puppet resource declaration.
          entity_resource = {
            :ensure     => :present,
            # The API identifies our resources by ID instead of by name.
            # We record that ID in the property_hash as it will be required if
            # Puppet needs to modify or delete the resource when applying the catalog.
            :id         => entity_json['id'],
            :name       => entity_json['name'],
            :attributes => entity_json['attributes']
          }

          # self.new is our class's constructor. This will create a full blown provider 
          # object from the above hash that describes its properties.
          # We then insert this newly created provider object into our entity_resources array.
          entity_providers << self.new(entity_resource)
        end
      end
    rescue Exception
      raise Puppet::Error, "Failed to query endpoint for entity list: #{$!}"
    end
    
    # Return the array back to Puppet (which could be empty)
    return entity_providers
  end

  # self.instances is called when you run the 'puppet resource' command. It's not actually
  # mandatory to define this method, but without it, 'puppet resource' won't work.

  # self.prefetch is closely related to self.instances, as you will see. This is called
  # when applying a manifest, and a number of resources of this type have been declared.
  # Puppet needs to know which of these resources exist on the system already.
  # In this case, the resource objects already exist, but Puppet needs to find providers
  # to manage their state on the system.
  def self.prefetch(managed_entities)
    
    # First we need to actually run our discovery routine in the above self.instances method.
    discovered_entities = self.instances

    # managed_entities is the list of resources that Puppet has passed to us, i.e.
    # those resources that have been declared. We need to compare each of these
    # with the resources we've discovered.
    managed_entities.keys.each do |entity_name|
      
      # This is how you search an array in Ruby... the supplied code block
      # is your comparison function:
      provider = discovered_entities.find do |entity|
        # Does the name match?
        entity.name == entity_name
      end
      
      # If there wasn't a match, then provider will be nil
      if provider
        managed_entities[entity_name].provider = provider
      end
    end
  end

  # When the resource has "ensure => present" but doesn't exist on the target system,
  # then we need to create it. 
  #
  # Note that within the create method we access the managed resource's properties
  # through the @resource instance variable, unlike the other methods where we use
  # the @property_hash instance variable.
  #
  # I don't actually know the reason behind this difference and would gladly accept
  # a pull request that clarifies the situation in this comment block!
  def create
    begin
      # The JSON library will generate a JSON document from a hash that we give it.
      # Instead of trying to template a JSON document, we can just programmatically
      # populate a hash and convert it safely in one shot.
      json_document_hash = {}
      json_document_hash['name'] = @resource['name']
      json_document_hash['attributes'] = @resource['attributes'] if @resource['attributes']

      # POST the JSON document to create the resource.
      response = self.class.rest_post('/', JSON.generate(json_document_hash))
    rescue Exception
      raise Puppet::Error, "Failed to create entity #{@resource[:name]}: #{$!}"
    end
  end

  # Puppet needs this method to exist and return a boolean value. We've already
  # run our discovery routine and know what exists on the system and what doesn't,
  # and those resources that do exist, we set :ensure to :present - so, we just
  # return the boolean result of this comparison here.
  def exists?
    @property_hash[:ensure] == :present
  end

  # When destroying a method, we need to know it's ID. The ID is what the API identifies
  # it as, whereas the name is what we identify it as. The ID will have been populated
  # in the property_hash during the self.instances discovery phase.
  def destroy
    begin
      self.class.rest_delete(sprintf('/%d', @property_hash[:id]))
    rescue Exception
      raise Puppet::Error, "Failed to delete entity #{@property_hash[:name]}: #{$!}"
    end
  end

end

