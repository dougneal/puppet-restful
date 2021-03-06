class Puppet::Provider::RestClient < Puppet::Provider
  
  # These libraries should be present on any plain old Ruby installation.
  require 'net/http'
  require 'uri'
  require 'json'

  # All the methods are class methods (self.method), for two reasons:
  #  - none of the methods ever need to access instance variables.
  #  - they will be called by other class methods, i.e. self.instances.
  
  def self.configuration
    path = File.join(Puppet[:confdir], 'restful-api.json')
    begin
      return JSON.parse(File.new(path).read)
    rescue Exception => e
      raise Puppet::Error, "puppet-restful couldn't load its configuration at #{path}: #{e.to_s}"
    end
  end

  def self.rest_get (endpoint, options = {})
    return rest_action(endpoint, Net::HTTP::Get, nil, options)
  end

  def self.rest_post (endpoint, content, options = {})
    return rest_action(endpoint, Net::HTTP::Post, content, options)
  end
  
  def self.rest_put (endpoint, content, options = {})
    return rest_action(endpoint, Net::HTTP::Put, content, options)
  end

  def self.rest_delete (endpoint, options = {})
    return rest_action(endpoint, Net::HTTP::Delete, nil, options)
  end
  
  def self.rest_action (endpoint, method, content, options)
    uri = URI(configuration['url'] + endpoint)

    http    = Net::HTTP.new(uri.host, uri.port)
    request = method.new(uri.request_uri)

    request.basic_auth configuration['username'], configuration['password']
    request['Accept'] = 'application/json'

    if not content.nil? then
      request['Content-Type'] = 'application/json'
      request.body = content
    end

    response = http.request(request)

    if not response.is_a?(Net::HTTPSuccess) then
      raise Puppet::Error, "REST endpoint responded with HTTP #{response.code}: \"#{response.body}\""
    end

    return JSON.parse(response.body)

  end
  
end

