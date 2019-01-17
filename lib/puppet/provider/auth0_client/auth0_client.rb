require 'puppet/resource_api/simple_provider'
require 'puppet/util/network_device/auth0_tenant/device'

# Implementation for the auth0_client type using the Resource API.
class Puppet::Provider::Auth0Client::Auth0Client < Puppet::ResourceApi::SimpleProvider
  def get(context)
    clients(context).map do |data|
      {
        ensure: 'present',
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
      }
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    jwt_configuration = {
      lifetime_in_seconds: should.delete(:jwt_lifetime_in_seconds),
      alg: should.delete(:jwt_alg),
    }.compact
    should[:jwt_configuration] = jwt_configuration unless jwt_configuration.empty?
    should.delete(:ensure)
    context.device.create_client(name, should)
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    jwt_configuration = {
      lifetime_in_seconds: should.delete(:jwt_lifetime_in_seconds),
      alg: should.delete(:jwt_alg),
    }.compact
    should[:jwt_configuration] = jwt_configuration unless jwt_configuration.empty?
    should.delete(:ensure)
    context.device.patch_client(get_client_id_by_name(context,name),should)
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    context.device.delete_client(get_client_id_by_name(context,name))
  end

  private
  def get_client_id_by_name(context,name)
    found_clients = clients(context).find_all {|c| c['name'] == name }
    context.warning("Found #{found_clients.count} clients with the name #{name}, choosing the first one.")
    found_clients.dig(0,'client_id')
  end

  def clients(context)
    @__clients ||= context.device.connection.get_clients.reject {|c| c['name'] == 'All Applications' }
  end
end
