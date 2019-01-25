require 'puppet/resource_api/simple_provider'
require_relative '../../util/network_device/auth0_tenant/device'

# Implementation for the auth0_client_grant type using the Resource API.
class Puppet::Provider::Auth0ClientGrant::Auth0ClientGrant < Puppet::ResourceApi::SimpleProvider
  def get(context)
    client_grants(context).map do |data|
      {
        ensure: 'present', 
        client_name: get_client_name_by_id(context,data['client_id']),
        audience: data['audience'],
        scopes: data['scope'],
      }
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name[:title]}' with #{should.inspect}")
    context.device.create_client_grant(
      client_id: get_client_id_by_name(context,should[:client_name]),
      audience: should[:audience],
      scope: should[:scopes],
    )
  end

  def update(context, name, should)
    context.notice("Updating '#{name[:title]}' with #{should.inspect}")
    client_id = get_client_id_by_name(context,should[:client_name])
    grant_id = get_client_grant_id(context,client_id,should[:audience])
    context.device.patch_client_grant(grant_id,should[:scopes])
  end

  def delete(context, name)
    context.notice("Deleting '#{name[:title]}'")
    client_id = get_client_id_by_name(context,name[:client_name])
    grant_id = get_client_grant_id(context,client_id,name[:audience])
    context.device.delete_client_grant(grant_id)
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
    @__clients ||= context.device.get_clients
  end

  def get_client_id_by_name(context,name)
    found_clients = clients(context).find_all {|c| c['name'] == name }
    context.warning("Found #{found_clients.count} clients with the name #{name}, choosing the first one.") if found_clients.count > 1
    found_clients.dig(0,'client_id')
  end

  def get_client_name_by_id(context,client_id)
    found_client = clients(context).find {|c| c['client_id'] == client_id}
    found_client ? found_client['name'] : nil
  end

end
