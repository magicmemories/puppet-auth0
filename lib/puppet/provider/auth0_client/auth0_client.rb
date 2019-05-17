require 'puppet/resource_api/simple_provider'
require_relative '../../util/network_device/auth0_tenant/device'

# Implementation for the auth0_client type using the Resource API.
class Puppet::Provider::Auth0Client::Auth0Client < Puppet::ResourceApi::SimpleProvider
  def get(context)
    clients(context).map do |data|
      id = data.dig('client_metadata','puppet_resource_identifier')
      if id.nil?
        context.warning("Auth0 Client #{data['name']} does not have a puppet_resource_identifier in its metadata. Using the client_id as the namevar.")
        id = "*#{data['client_id']}"
      end
      {
        ensure: 'present',
        puppet_resource_identifier: id,
        name: data['name'],
        description: data['description'],
        app_type: data['app_type'],
        logo_uri: data['logo_uri'],
        oidc_conformant: data['oidc_conformant'],
        callbacks: data['callbacks'],
        allowed_origins: data['allowed_origins'],
        web_origins: data['web_origins'],
        client_aliases: data['client_aliases'],
        allowed_logout_urls: data['allowed_logout_urls'],
        grant_types: data['grant_types'],
        token_endpoint_auth_method: data['token_endpoint_auth_method'],
        sso: data['sso'],
        sso_disabled: data['sso_disabled'],
        jwt_lifetime_in_seconds: data.dig('jwt_configuration','lifetime_in_seconds'),
        jwt_alg: data.dig('jwt_configuration','alg'),
        client_id: data['client_id'],
      }
    end
  end

  def create(context, puppet_resource_identifier, should)
    context.notice("Creating '#{puppet_resource_identifier}' with #{should.inspect}")
    jwt_configuration = {
      lifetime_in_seconds: should.delete(:jwt_lifetime_in_seconds),
      alg: should.delete(:jwt_alg),
    }.compact
    should[:jwt_configuration] = jwt_configuration unless jwt_configuration.empty?
    should.delete(:ensure)
    should[:client_metadata] ||= {}
    should[:client_metadata]['puppet_resource_identifier'] = should.delete(:puppet_resource_identifier)
    context.device.create_client(should[:name], should)
  end

  def update(context, puppet_resource_identifier, should)
    context.notice("Updating '#{puppet_resource_identifier}' with #{should.inspect}")
    jwt_configuration = {
      lifetime_in_seconds: should.delete(:jwt_lifetime_in_seconds),
      alg: should.delete(:jwt_alg),
    }.compact
    should[:jwt_configuration] = jwt_configuration unless jwt_configuration.empty?
    should.delete(:ensure)
    should.delete(:puppet_resource_identifier)
    should[:client_metadata]['puppet_resource_identifier'] = puppet_resource_identifier if should.has_key?(:client_metadata)
    context.device.patch_client(get_client_id_by_puppet_identifier(context,puppet_resource_identifier),should)
  end

  def delete(context, puppet_resource_identifier)
    context.notice("Deleting '#{puppet_resource_identifier}'")
    context.device.delete_client(get_client_id_by_puppet_identifier(context,puppet_resource_identifier))
  end

  def canonicalize(context,resources)
    resources.each do |resource|
      remote_client = get_client_by_puppet_identifier(context,resource[:puppet_resource_identifier])
      if remote_client
        %i{callbacks allowed_origins web_origins allowed_logout_urls}.each do |prop|
          if resource.delete(:"keep_extra_#{prop}") && resource[prop] && remote_client[prop.to_s]
            resource[prop] += (remote_client[prop.to_s] - resource[prop])
          end
        end
      end
    end
  end

  private
  def get_client_id_by_name(context,name)
    get_client_by_name(context,name)&.[]('client_id')
  end

  def get_client_id_by_puppet_identifier(context,id)
    get_client_by_puppet_identifier(context,id)&.[]('client_id')
  end

  def get_client_by_name(context,name)
    found_clients = clients(context).find_all {|c| c['name'] == name }
    context.warning("Found #{found_clients.count} clients with the name #{name}, choosing the first one.") if found_clients.count > 1
    found_clients[0]
  end

  def get_client_by_puppet_identifier(context,id)
    found_clients = clients(context).find_all {|c| c.dig('client_metadata','puppet_resource_identifier') == id }
    context.warning("Found #{found_clients.count} clients whose puppet_resource_identifier is #{id}, choosing the first one.") if found_clients.count > 1
    found_clients[0]
  end

  def clients(context)
    @__clients ||= context.device.clients.reject {|c| c['name'] == 'All Applications' }
  end
end
