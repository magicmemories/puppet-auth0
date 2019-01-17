require 'puppet/resource_api/simple_provider'
require 'puppet/util/network_device/auth0_tenant/device'

# Implementation for the auth0_connection type using the Resource API.
class Puppet::Provider::Auth0Connection::Auth0Connection < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'foo',
        ensure: 'present',
      },
      {
        name: 'bar',
        ensure: 'present',
      },
    ]
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end
end
