require 'spec_helper'
require 'puppet/pops/adapters/auth0_adapter'
require 'pry'

RSpec.describe 'auth0_get_client_credentials' do
  let(:management_client_id) { 'management_id' }
  let(:management_client_secret) { 'management_secret' }
  let(:tenant_domain) { 'example.auth0.com' }
  let(:target_result) { {'client_id' => 'abcd1234', 'client_secret' => 'asecrettoeveryone'} }
  let(:target_client) { build(:client_api, name: 'Foo Bar', client_id: 'abcd1234', client_secret: 'asecrettoeveryone') }
  let(:other_clients) { build_list(:client_api,5) }
  let(:problem_client) { build(:client_api, name: 'Foo Bar', client_id: 'efgh5678', client_secret: 'masterusingit') }

  let(:auth0_adapter) { instance_double('Puppet::Pops::Adapters::Auth0Adapter','auth0_adapter') }
  let(:auth0_client) { double('auth0_client') } # Auth0::Client doesn't mixin Auth0::Api::V2 until it's instantiated so instance_double doesn't work

  before(:each) do
    allow(Puppet::Pops::Adapters::Auth0Adapter).to receive(:adapt).and_return(auth0_adapter)
    allow(auth0_adapter).to receive(:client).and_return(auth0_client)
    allow(auth0_client).to receive(:get_clients).with(fields: ['name','client_id','client_secret']).and_return(api_data)
  end

  shared_context 'hiera' do
    before(:each) do
      allow(scope).to receive(:call_function).with('lookup','auth0::management_client_id').and_return(management_client_id)
      allow(scope).to receive(:call_function).with('lookup','auth0::management_client_secret').and_return(management_client_secret)
      allow(scope).to receive(:call_function).with('lookup','auth0::tenant_domain').and_return(tenant_domain)
    end
  end

  context 'when exactly one client with the requested name exists' do
    let(:api_data) { other_clients + [target_client] }

    context 'with management api credentials passed explicitly' do
      it { is_expected.to run.with_params('Foo Bar',management_client_id,management_client_secret,tenant_domain).and_return(target_result) }
    end

    context 'with management api credentials in hiera' do
      include_context 'hiera'
      it { is_expected.to run.with_params('Foo Bar').and_return(target_result) }
    end 
  end

  context 'when no client with the requested name exists' do
    let(:api_data) { other_clients }

    context 'with management api credentials passed explicitly' do
      it { is_expected.to run.with_params('Foo Bar',management_client_id,management_client_secret,tenant_domain).and_return(nil) }
    end

    context 'with management api credentials in hiera' do
      include_context 'hiera'
      it { is_expected.to run.with_params('Foo Bar').and_return(nil) }
    end
  end

  context 'when multiple clients with the requested name exist' do
    let(:api_data) { other_clients + [target_client,problem_client] }

    context 'with management api credentials passed explicitly' do
      it 'issues a warning' do
        expect(Puppet).to receive(:warning).with(/\AFound \d+ clients with the name/)
        is_expected.to run.with_params('Foo Bar',management_client_id,management_client_secret,tenant_domain)
      end
    end

    context 'with management api credentials in hiera' do
      include_context 'hiera'
      it 'issues a warning' do
        expect(Puppet).to receive(:warning).with(/\AFound \d+ clients with the name/)
        is_expected.to run.with_params('Foo Bar')
      end
    end
  end
end