require 'puppet/resource_api/simple_provider'
require_relative '../../util/network_device/auth0_tenant/device'

# Implementation for the auth0_client_grant type using the Resource API.
class Puppet::Provider::Auth0ClientGrant::Auth0ClientGrant < Puppet::ResourceApi::SimpleProvider
  def get(context)
    client_grants(context).map do |data|
      res = get_client_puppet_resource_identifier_by_id(context,data['client_id'])
      aud = data['audience'] 
      {
        title: "#{res} -> #{aud}",
        ensure: 'present', 
        client_resource: res,
        audience: aud,
        scopes: data['scope'],
        client_id: data['client_id'],
      }
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name[:title]}' with #{should.inspect}")
    result = context.device.create_client_grant(
      client_id: get_client_id_by_puppet_resource_identifier(context,should[:client_resource]),
      audience: should[:audience],
      scope: should[:scopes],
    )
    Puppet.debug("Got response: #{result.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name[:title]}' with #{should.inspect}")
    client_id = get_client_id_by_puppet_resource_identifier(context,should[:client_resource])
    grant_id = get_client_grant_id(context,client_id,should[:audience])
    result = context.device.patch_client_grant(grant_id,scope: should[:scopes])
    Puppet.debug("Got response: #{result.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name[:title]}'")
    client_id = get_client_id_by_puppet_resource_identifier(context,name[:client_resource])
    grant_id = get_client_grant_id(context,client_id,name[:audience])
    result = context.device.delete_client_grant(grant_id)
    Puppet.debug("Got response: #{result.inspect}")
  end

  private
  def client_grants(context)
    @__client_grants ||= context.device.get_all_client_grants
  end

  def get_client_grant_id(context,client_id,audience)
    grant = client_grants(context).find {|cg| cg['client_id'] == client_id && cg['audience'] == audience }
    grant['id']
  end

  def clients(context)
    @__clients ||= context.device.get_clients.reject {|c| c['global'] }
  end

  def get_client_id_by_puppet_resource_identifier(context,resource_identifier)
    found_clients = clients(context).find_all {|c| c.dig('client_metadata','puppet_resource_identifier') == resource_identifier }
    context.warning("Found #{found_clients.count} clients whose puppet_resource_identifier is #{resource_identifier}, choosing the first one.") if found_clients.count > 1
    found_clients.dig(0,'client_id')
  end

  def get_client_puppet_resource_identifier_by_id(context,client_id)
    if found_client = clients(context).find {|c| c['client_id'] == client_id}
      if resource_identifier = found_client.dig('client_metadata','puppet_resource_identifier')
        resource_identifier
      else
        context.warning("Auth0 Client #{found_client['name']} does not have a puppet_resource_identifier in its metadata. Using the client_id as the namevar.")
        "*#{found_client['client_id']}"
      end
    end
  end

end
