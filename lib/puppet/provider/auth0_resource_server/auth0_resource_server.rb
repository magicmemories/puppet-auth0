require 'puppet/resource_api/simple_provider'
require_relative '../../util/network_device/auth0_tenant/device'

# Implementation for the auth0_resource_server type using the Resource API.
class Puppet::Provider::Auth0ResourceServer::Auth0ResourceServer < Puppet::ResourceApi::SimpleProvider
  def get(context)
    apis(context).map do |data|
      {
        display_name: data['name'],
        identifier: data['identifier'],
        scopes: scopes_to_hash(data['scopes'] || []),
        signing_alg: data['signing_alg'],
        signing_secret: data['signing_secret'],
        allow_offline_access: data['allow_offline_access'],
        token_lifetime: data['token_lifetime'],
        skip_consent: data['skip_consent_for_verifiable_first_party_clients'],
      }.compact
    end
  end

  def create(context, identifier, should)
    context.notice("Creating '#{identifier}' with #{should.inspect}")
    data = transform_should(should)
    context.device.create_resource_server(identifier,data)
  end

  def update(context, identifier, should)
    context.notice("Updating '#{identifier}' with #{should.inspect}")
    data = transform_should(should)
    id = CGI.escape(identifier)
    context.device.patch_resouce_server(id,data)
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    id = CGI.escape(identifier)
    context.device.delete_resource_server(id)
  end

  private
  def apis(context)
    # TODO: handle paging in responses
    @__apis ||= context.device.get_resource_servers.reject {|c| c['name'] == 'Auth0 Management API' }
  end

  def scopes_to_hash(scopes)
    scopes.each_with_object({}) {|hash,scope| hash[scope['value']] = scope['description'] }
  end

  def hash_to_scopes(hash)
    hash.map {|k,v| { 'value' => k, 'description' => v } }
  end

  def transform_should(should)
    should[:skip_consent_for_verifiable_first_party_clients] = should.delete(:skip_consent) if should.has_key?(:skip_consent)
    should[:name] = should.delete(:display_name) if should.has_key?(:display_name)
    should[:scopes] = hash_to_scopes(should[:scopes]) if should.has_key?(:scopes)
    should.delete(:ensure)
    should
  end
end
