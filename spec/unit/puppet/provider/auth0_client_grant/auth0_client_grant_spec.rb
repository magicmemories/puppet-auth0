require 'spec_helper'

ensure_module_defined('Puppet::Provider::Auth0ClientGrant')
require 'puppet/provider/auth0_client_grant/auth0_client_grant'

RSpec.describe Puppet::Provider::Auth0ClientGrant::Auth0ClientGrant do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:auth0_tenant) { instance_double('Puppet::Util::NetworkDevice::Auth0_tenant::Device', 'auth0_tenant') }

  before(:each) do
    allow(context).to receive(:device).and_return(auth0_tenant)
  end

  describe '#get' do
    it 'processes resources' do
      allow(subject).to receive(:get_client_puppet_resource_identifier_by_id).with(context,'abcd1234').and_return('foo')
      allow(auth0_tenant).to receive(:get_all_client_grants).and_return([
        {
          'client_id' => 'abcd1234',
          'audience'  => 'bar',
          'scope'     => ['foo:bar'],
        },
        {
          'client_id' => 'abcd1234',
          'audience'  => 'baz',
          'scope'    => ['foo:baz'],
        }
      ])

      expect(provider.get(context)).to eq [
        {
          ensure: 'present',
          client_resource: 'foo',
          audience: 'bar',
          scopes: ['foo:bar'],
        },
        {
          ensure: 'present',
          client_resource: 'foo',
          audience: 'baz',
          scopes: ['foo:baz']
        },
      ]
    end
  end

  describe '#create(context, name, should)' do
    it 'creates the resource' do
      allow(subject).to receive(:get_client_id_by_puppet_resource_identifier).with(context,'foo').and_return('abcd1234')
      expect(context).to receive(:notice).with(%r{\ACreating 'foo -> bar'})
      expect(auth0_tenant).to receive(:create_client_grant).with(client_id: 'abcd1234', audience: 'bar', scope: nil)

      provider.create(context, {title: 'foo -> bar', client_resource: 'foo', audience: 'bar'}, client_resource: 'foo', audience: 'bar', ensure: 'present')
    end
  end

  describe '#update(context, name, should)' do
    it 'updates the resource' do
      allow(subject).to receive(:get_client_id_by_puppet_resource_identifier).with(context,'foo').and_return('abcd1234')
      allow(subject).to receive(:get_client_grant_id).with(context,'abcd1234','bar').and_return('efgh5678')
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo -> bar'})
      expect(auth0_tenant).to receive(:patch_client_grant).with('efgh5678', {'scopes' => ['foo:bar']})

      provider.update(context, {title: 'foo -> bar', client_resource: 'foo', audience: 'bar'}, client_resource: 'foo', audience: 'bar', scopes: ['foo:bar'], ensure: 'present')
    end
  end

  describe '#delete(context, name, should)' do
    it 'deletes the resource' do
      allow(subject).to receive(:get_client_id_by_puppet_resource_identifier).with(context,'foo').and_return('abcd1234')
      allow(subject).to receive(:get_client_grant_id).with(context,'abcd1234','bar').and_return('efgh5678')
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo -> bar'})
      expect(auth0_tenant).to receive(:delete_client_grant).with('efgh5678')

      provider.delete(context, {title: 'foo -> bar', client_resource: 'foo', audience: 'bar'})
    end
  end
end
