require 'spec_helper'

ensure_module_defined('Puppet::Provider::Auth0ClientGrant')
require 'puppet/provider/auth0_client_grant/auth0_client_grant'

RSpec.describe Puppet::Provider::Auth0ClientGrant::Auth0ClientGrant do
  subject(:provider) { Puppet::Provider::Auth0ClientGrant::Auth0ClientGrant.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:auth0_tenant) { instance_double('Puppet::Util::NetworkDevice::Auth0_tenant::Device', 'auth0_tenant') }

  before(:each) do
    allow(context).to receive(:device).and_return(auth0_tenant)
    allow(auth0_tenant).to receive(:get_clients).and_return(build_list(:client_api,1,{
      client_id: 'abcd1234',
      client_metadata: {
        'puppet_resource_identifier' => 'foo',
      },
    }))
    allow(auth0_tenant).to receive(:get_all_client_grants).and_return([
      {
        'client_id' => 'abcd1234',
        'audience'  => 'bar',
        'scope'     => ['foo:bar'],
        'id'        => 'efgh5678',
      },
      {
        'client_id' => 'abcd1234',
        'audience'  => 'baz',
        'scope'     => ['foo:baz'],
        'id'        => 'ijkl9012',
      }
    ])
  end

  describe '#get' do
    it 'processes resources' do
      expect(provider.get(context)).to eq [
        {
          ensure: 'present',
          title: 'foo -> bar',
          client_id: 'abcd1234',
          client_resource: 'foo',
          audience: 'bar',
          scopes: ['foo:bar'],
        },
        {
          ensure: 'present',
          title: 'foo -> baz',
          client_id: 'abcd1234',
          client_resource: 'foo',
          audience: 'baz',
          scopes: ['foo:baz']
        },
      ]
    end

    context "when a client doesn't have a puppet_resource_identifier" do      
      it 'warns about missing identifier and uses client_id instead' do
        allow(auth0_tenant).to receive(:get_clients).and_return(build_list(:client_api,1,{
          client_id: 'abcd1234',
          client_metadata: {}
        }))
        expect(context).to receive(:warning).with(%r{does not have a puppet_resource_identifier in its metadata})
        expect(provider.get(context)).to include(a_hash_including(client_resource: "*abcd1234"))
      end
    end
  end

  describe '#create(context, name, should)' do
    it 'creates the resource' do
      #allow(subject).to receive(:get_client_id_by_puppet_resource_identifier).with(context,'foo').and_return('abcd1234')
      expect(context).to receive(:notice).with(%r{\ACreating 'foo -> bar'})
      expect(auth0_tenant).to receive(:create_client_grant).with(client_id: 'abcd1234', audience: 'bar', scope: nil)

      provider.create(context, {title: 'foo -> bar', client_resource: 'foo', audience: 'bar'}, client_resource: 'foo', audience: 'bar', ensure: 'present')
    end
  end

  describe '#update(context, name, should)' do
    it 'updates the resource' do

      expect(context).to receive(:notice).with(%r{\AUpdating 'foo -> bar'})
      expect(auth0_tenant).to receive(:patch_client_grant).with('efgh5678', {scope: ['foo:bar']})

      provider.update(context, {title: 'foo -> bar', client_resource: 'foo', audience: 'bar'}, client_resource: 'foo', audience: 'bar', scopes: ['foo:bar'], ensure: 'present')
    end
  end

  describe '#delete(context, name, should)' do

    it 'deletes the resource' do
      #allow(subject).to receive(:get_client_id_by_puppet_resource_identifier).with(context,'foo').and_return('abcd1234')
      #allow(subject).to receive(:get_client_grant_id).with(context,'abcd1234','bar').and_return('efgh5678')
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo -> bar'})
      expect(auth0_tenant).to receive(:delete_client_grant).with('efgh5678')

      provider.delete(context, {title: 'foo -> bar', client_resource: 'foo', audience: 'bar'})
    end

    # This is mostly used for purging unmanaged resources
    it 'can delete a grant for an identifierless client' do
      allow(auth0_tenant).to receive(:get_clients).and_return(build_list(:client_api,1,{
        client_id: 'abcd1234',
        client_metadata: {}
      }))
      expect(context).to receive(:notice).with(%r{\ADeleting '\*abcd1234 -> bar'})
      expect(auth0_tenant).to receive(:delete_client_grant).with('efgh5678')

      provider.delete(context, {title: '*abcd1234 -> bar', client_resource: '*abcd1234', audience: 'bar'})
    end
  end
end
