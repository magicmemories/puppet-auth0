require 'puppet/resource_api/simple_provider'

# Implementation for the auth0_connection type using the Resource API.
class Puppet::Provider::Auth0Connection::Auth0Connection < Puppet::ResourceApi::SimpleProvider
  def get(context)
    connections(context).map do |data|
      {
        ensure: 'present',
        name: data['name'],
        strategy: data['strategy'],
        options: data['options'],
        clients: (data['enabled_clients'] || []).map {|id| client_resource_identifier_by_id(context,id) }.sort,
        realms: (data['realms'] || []),
      }.compact
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    context.device.create_connection({
      name: should[:name],
      strategy: should[:strategy],
      options: should[:options],
      realms: should[:realms],
      enabled_clients: (should.has_key?(:clients) ? should[:clients].map {|cpri| client_id_by_resource_identifier(context,cpri) } : nil),
    }.compact)
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    id = get_connection_id_by_name(context, name)
    context.device.update_connection(id, {
      options: should[:options],
      realms: should[:realms],
      enabled_clients: (should.has_key?(:clients) ? should[:clients].map {|cpri| client_id_by_resource_identifier(context,cpri) } : nil),
    }.compact)
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    id = get_connection_id_by_name(context,name)
    context.device.delete_connection(id)
  end

  def canonicalize(context,resources)
    resources.each do |resource|
      remote_connection = get_connection_by_name(context,resource[:name])
      if remote_connection
        if resource.delete(:keep_extra_clients) && resource[:clients] && remote_connection['enabled_clients']
          remote_clients = remote_connection['enabled_clients'].map {|id| client_resource_identifier_by_id(context, id) }
          unmanaged_clients = (remote_clients - resource[:clients])
          context.debug("Keeping extra clients for #{resource[:name]}: #{unmanaged_clients.inspect}") unless unmanaged_clients.empty?
          resource[:clients] += unmanaged_clients
        end
        if resource.delete(:keep_extra_options) && resource[:options] && remote_connection['options']
          unmanaged_options = remote_connection['options'].reject {|k,v| resource[:options].has_key?(k) }
          context.debug("Keeping extra options for #{resource[:name]}: #{unmanaged_options.inspect}") unless unmanaged_options.empty?
          resource[:options] = remote_connection['options'].merge(resource[:options])
        end
      end
      resource[:clients] = resource[:clients].sort if resource[:clients].kind_of?(Array)
    end
  end

  private

  def connections(context)
    @__connections ||= context.device.get_connections()
  end

  def get_connection_id_by_name(context, name)
    get_connection_by_name(context,name)['id']
  end

  def get_connection_by_name(context,name)
    connections(context).find {|c| c['name'] == name }
  end

  def client_resource_identifier_by_id(context,client_id)
    if found_client = clients(context).find {|c| c['client_id'] == client_id}
      if resource_identifier = found_client.dig('client_metadata','puppet_resource_identifier')
        resource_identifier
      else
        Puppet::Provider::Auth0Client::Auth0Client.warn_about(found_client['name'],context)
        "*#{found_client['client_id']}"
      end
    end
  end

  def client_id_by_resource_identifier(context,resource_identifier)
    if resource_identifier =~ /^\*/
      # This is a "dummy" resource identifier that is actually a client_id, for an existing
      # client without any resource identifier in the metadata.
      resource_identifier[1..-1]
    else
      # This is a real resource identifier and we should look it up in the client metadata.
      found_clients = clients(context).find_all {|c| c.dig('client_metadata','puppet_resource_identifier') == resource_identifier }
      context.warning("Found #{found_clients.count} clients whose puppet_resource_identifier is #{resource_identifier}, choosing the first one.") if found_clients.count > 1
      found_clients.dig(0,'client_id')
    end
  end
  
  def clients(context)
    @__clients ||= context.device.get_clients.reject {|c| c['global'] }
  end
end
