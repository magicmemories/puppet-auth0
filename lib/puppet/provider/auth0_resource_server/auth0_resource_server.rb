require 'puppet/resource_api/simple_provider'
require_relative '../../util/network_device/auth0_tenant/device'

# Implementation for the auth0_resource_server type using the Resource API.
class Puppet::Provider::Auth0ResourceServer::Auth0ResourceServer < Puppet::ResourceApi::SimpleProvider
  def prefetch(resources)
    items = instances
    resources.each_pair do |name,resource|
      if provider = items.find { |item| item.name == name.to_s }
        resource.provider = provider
      end
    end
  end

  def get(context)
    apis(context).map do |data|
      {
        ensure: 'present',
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
    result = context.device.create_resource_server(identifier,data)
    Puppet.debug("Got response: #{result.inspect}")
  end

  def update(context, identifier, should)
    context.notice("Updating '#{identifier}' with #{should.inspect}")
    data = transform_should(should)
    id = CGI.escape(identifier)
    result = context.device.patch_resource_server(id,data)
    Puppet.debug("Got response: #{result.inspect}")
  end

  def delete(context, identifier)
    context.notice("Deleting '#{identifier}'")
    id = CGI.escape(identifier)
    result = context.device.delete_resource_server(id)
    Puppet.debug("Got response: #{result.inspect}")
  end

  private
  def apis(context)
    @__apis ||= context.device.get_resource_servers.reject {|c| c['is_system'] }
  end

  def scopes_to_hash(scopes)
    scopes.each_with_object({}) {|scope,hash| hash[scope['value']] = scope['description'] }
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
