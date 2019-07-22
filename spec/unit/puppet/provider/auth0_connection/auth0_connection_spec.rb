require 'spec_helper'

ensure_module_defined('Puppet::Provider::Auth0Connection')
require 'puppet/provider/auth0_connection/auth0_connection'

RSpec.describe Puppet::Provider::Auth0Connection::Auth0Connection do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:auth0_tenant) { instance_double('Puppet::Util::NetworkDevice::Auth0_tenant::Device', 'auth0_tenant') }

  before(:each) do
    allow(context).to receive(:device).and_return(auth0_tenant)
    allow(auth0_tenant).to receive(:get_connections).and_return(
      [
        {
          'id'                   => 'con_0000000000000001',
          'name'                 => 'Foo',
          'display_name'         => 'Foo',
          'options'              => {},
          'strategy'             => 'auth0',
          'realms'               => [
            'Foo',
          ],
          'enabled_clients'      => ['abcd'],
          'is_domain_connection' => false,
          'metadata'             => {},
        },
        {
          'id'                   => 'con_0000000000000002',
          'name'                 => 'Bar',
          'display_name'         => 'Bar',
          'options'              => {},
          'strategy'             => 'custom',
          'realms'               => [
            'Bar',
          ],
          'enabled_clients'      => ['efgh'],
          'is_domain_connection' => false,
          'metadata'             => {},
        },
      ]
    )
    allow(auth0_tenant).to receive(:get_clients).and_return([
      build(:client_api,{ name: 'client_1', client_id: 'abcd'}),
      build(:client_api,{ name: 'client_2', client_id: 'efgh'}),
      build(:client_api,{ name: 'client_3', client_id: 'ijkl'}),
    ])
  end

  describe '#get' do
    it 'processes resources' do
      expect(provider.get(context)).to eq [
        {
          name: 'Foo',
          ensure: 'present',
          strategy: 'auth0',
          options: {},
          realms: ['Foo'],
          clients: ['client_1'],
        },
        {
          name: 'Bar',
          ensure: 'present',
          strategy: 'custom',
          options: {},
          realms: ['Bar'],
          clients: ['client_2'],
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'Foo'})
      expect(auth0_tenant).to receive(:create_connection).with({name: 'Foo', strategy: 'auth0', realms: ['Bar'], enabled_clients: ['ijkl']})

      provider.create(context, 'Foo', name: 'Foo', ensure: 'present', strategy: 'auth0', realms: ['Bar'], clients: ['client_3'])
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'Bar'})
      expect(auth0_tenant).to receive(:update_connection).with('con_0000000000000002',{
        options: { 'baz' => 'mux' },
        realms: ['Bar'],
        enabled_clients: ['ijkl'],
      })

      provider.update(context, 'Bar', {
        name: 'Bar',
        ensure: 'present',
        strategy: 'custom',
        options: {
          'baz' => 'mux',
        },
        realms: ['Bar'],
        clients: ['client_3'],
      })
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'Foo'})
      expect(auth0_tenant).to receive(:delete_connection).with('con_0000000000000001')

      provider.delete(context, 'Foo')
    end
  end
end
