require 'spec_helper'

ensure_module_defined('Puppet::Provider::Auth0ResourceServer')
require 'puppet/provider/auth0_resource_server/auth0_resource_server'

RSpec.describe Puppet::Provider::Auth0ResourceServer::Auth0ResourceServer do
  subject(:provider) { Puppet::Provider::Auth0ResourceServer::Auth0ResourceServer.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:auth0_tenant) { instance_double('Puppet::Util::NetworkDevice::Auth0_tenant::Device', 'auth0_tenant') }

  before(:each) do
    allow(context).to receive(:device).and_return(auth0_tenant)
  end

  describe '#get' do
    it 'processes resources' do
      allow(auth0_tenant).to receive(:get_resource_servers).and_return(
        [
          {
            'identifier' => 'http://foo.com',
            'name'       => 'Foo',
            'scopes'     => [{'value' => 'foo:read', 'description' => 'Read foo' }],
          },
          {
            'identifier' => 'http://bar.com',
            'name'       => 'Bar',
            'skip_consent_for_verifiable_first_party_clients' => true,
          },
        ]
      )

      expect(provider.get(context)).to eq [
        {
          ensure: 'present',
          identifier: 'http://foo.com',
          display_name: 'Foo',
          scopes: {'foo:read' => 'Read foo'},
        },
        {
          ensure: 'present',
          identifier: 'http://bar.com',
          display_name: 'Bar',
          skip_consent: true,
          scopes: {},
        },
      ]
    end
  end

  describe '#create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'http://foo.com'})
      expect(auth0_tenant).to receive(:create_resource_server).with('http://foo.com',{name: 'foo'})

      provider.create(context, 'http://foo.com', display_name: 'foo', ensure: 'present')
    end

    it 'creates resources with scopes correctly' do
      expect(context).to receive(:notice).with(%r{\ACreating 'http://foo.com'})
      expect(auth0_tenant).to receive(:create_resource_server).with('http://foo.com',{
        name: 'foo',
        scopes: [{ 'value' => 'read:foo', 'description' => 'Read access to Foo'}],
      })

      provider.create(context, 'http://foo.com', {
        display_name: 'foo',
        ensure: 'present',
        scopes: { 'read:foo' => 'Read access to Foo'},
      })
    end
  end

  describe '#update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'http://foo.com'})
      expect(auth0_tenant).to receive(:patch_resource_server).with('http%3A%2F%2Ffoo.com',{name: 'bar'})

      provider.update(context, 'http://foo.com', display_name: 'bar', ensure: 'present')
    end

    it 'handles updating scopes correctly' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'http://foo.com'})
      expect(auth0_tenant).to receive(:patch_resource_server).with('http%3A%2F%2Ffoo.com',{
        scopes: [
          { 'value' => 'read:foo',  'description' => 'Read access to Foo'  },
          { 'value' => 'write:foo', 'description' => 'Write access to Foo' },
        ]
      })
      provider.update(context, 'http://foo.com', scopes: {
        'read:foo'  => 'Read access to Foo',
        'write:foo' => 'Write access to Foo' ,
      })
    end
  end

  describe '#delete(context, name, should)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'http://foo.com'})
      expect(auth0_tenant).to receive(:delete_resource_server).with('http%3A%2F%2Ffoo.com')

      provider.delete(context, 'http://foo.com')
    end
  end
end
