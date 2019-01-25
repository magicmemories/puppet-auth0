require 'spec_helper'

ensure_module_defined('Puppet::Provider::Auth0Rule')
require 'puppet/provider/auth0_rule/auth0_rule'

RSpec.describe Puppet::Provider::Auth0Rule::Auth0Rule do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:auth0_tenant) { instance_double('Puppet::Util::NetworkDevice::Auth0_tenant::Device', 'auth0_tenant') }

  before(:each) do
    allow(context).to receive(:device).and_return(auth0_tenant)
  end

  describe '#get' do
    it 'processes resources' do
      allow(auth0_tenant).to receive(:get_rules).and_return([
        {
          'name'    => 'foo',
          'script'  => 'AAA',
          'order'   => 0,
          'enabled' => true,
          'stage'   => 'login_success',
        },
        {
          'name'    => 'bar',
          'script'  => 'BBB',
          'order'   => 1,
          'enabled' => false,
          'stage'   => 'login_failure',
        },
      ])

      expect(provider.get(context)).to eq [
        {
          ensure: 'present',
          name: 'foo',
          script: 'AAA',
          order: 0,
          enabled: true,
          run_stage: 'login_success'
        },
        {
          ensure: 'present',
          name: 'bar',
          script: 'BBB',
          order: 1,
          enabled: false,
          run_stage: 'login_failure',
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'a'})
      expect(auth0_tenant).to receive(:create_rule).with('a','b',1,true,'login_success')

      provider.create(context, 'a', name: 'a', script: 'b', order: 1, enabled: true, run_stage: 'login_success')
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      allow(subject).to receive(:get_rule_id_by_name).with(context,'foo').and_return('abcd1234')
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})
      expect(auth0_tenant).to receive(:update_rule).with('abcd1234',{'script' => 'bar'})

      provider.update(context, 'foo', name: 'foo', script: 'bar', ensure: 'present')
    end
  end

  describe 'delete(context, name, should)' do
    it 'deletes the resource' do
      allow(subject).to receive(:get_rule_id_by_name).with(context,'foo').and_return('abcd1234')
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})
      expect(auth0_tenant).to receive(:delete_rule).with('abcd1234')

      provider.delete(context, 'foo')
    end
  end
end
