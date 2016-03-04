class Puppet::Provider::RestClient < Puppet::Provider
  
  require 'net/http'
  require 'uri'
  require 'json'

  def self.configuration
    #path = File.join(Puppet[:confdir], 'restful-api.json')
    #if File.exists?(path)
    #  return JSON.parse(File.new(path))
    #end

    #return {}
    return {
      'url' => 'http://localhost:3000/muppets'
    }
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
    end

    response = http.request(request)

    if not response.is_a?(Net::HTTPSuccess) then
      raise Puppet::Error, "REST endpoint responded with HTTP #{response.code}: \"#{response.body}\""
    end

    return JSON.parse(response.body)

  end
  
end

