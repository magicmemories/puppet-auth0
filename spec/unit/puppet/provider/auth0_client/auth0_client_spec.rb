require 'spec_helper'
require 'pry'

ensure_module_defined('Puppet::Provider::Auth0Client')
require 'puppet/provider/auth0_client/auth0_client'

RSpec.describe Puppet::Provider::Auth0Client::Auth0Client do
  subject(:provider) { Puppet::Provider::Auth0Client::Auth0Client.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:auth0_tenant) { instance_double('Puppet::Util::NetworkDevice::Auth0_tenant::Device', 'auth0_tenant') }

  before(:each) do
    allow(context).to receive(:device).and_return(auth0_tenant)
  end
  
  describe '#get' do
    let(:base) { attributes_for(:client) }
    let(:api_data) { [build(:client_api,base)] }
    let(:resource_data) { [build(:client_resource,base)] }
    let(:get_response) { api_data }

    before(:each) do
      allow(auth0_tenant).to receive(:clients).and_return(api_data)
    end

    it 'returns appropriate data struct' do
      expect(provider.get(context)).to eq(resource_data)
    end

    context "when a client doesn't have a puppet_resource_identifier" do
      let(:base) { attributes_for(:client).tap {|attrs| attrs[:client_metadata].delete('puppet_resource_identifier') } }
      
      it 'warns about missing identifier and uses client_id instead' do
        expect(context).to receive(:warning).with(%r{does not have a puppet_resource_identifier in its metadata})
        expect(provider.get(context)).to include(a_hash_including(puppet_resource_identifier: "*#{base[:client_id]}"))
      end
    end
  end

  describe '#create(context, puppet_resource_identifier, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'foo_bar'})
      expect(auth0_tenant).to receive(:create_client).with('Foo', {
        'name'            => 'Foo',
        'app_type'        => 'spa',
        'client_metadata' => {
          'puppet_resource_identifier' => 'foo_bar',
        }
      })

      provider.create(context, 'foo_bar', puppet_resource_identifier: 'foo_bar', display_name: 'Foo', ensure: 'present', app_type: 'spa')
    end
  end

  describe '#update(context, puppet_resource_identifier, should)' do
    it 'updates the resource' do
      allow(auth0_tenant).to receive(:clients).and_return(build_list(:client_api,1,{
        client_id: 'abcd1234',
        client_metadata: {
          'puppet_resource_identifier' => 'foo_bar',
        }
      }))
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo_bar'})
      expect(auth0_tenant).to receive(:patch_client).with('abcd1234', {
        'name'            => 'Foo',
        'app_type'        => 'non_interactive',
        'client_metadata' => {
          'puppet_resource_identifier' => 'foo_bar',
        }
      })

      provider.update(context, 'foo_bar', puppet_resource_identifier: 'foo_bar', display_name: 'Foo', ensure: 'present', app_type: 'non_interactive')
    end
  end

  describe '#delete(context, puppet_resource_identifier, should)' do
    it 'deletes the resource' do
      allow(auth0_tenant).to receive(:clients).and_return(build_list(:client_api,1,{
        client_id: 'abcd1234',
        client_metadata: {
          'puppet_resource_identifier' => 'foo_bar',
        }
      }))
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo_bar'})
      expect(auth0_tenant).to receive(:delete_client).with('abcd1234')

      provider.delete(context, 'foo_bar')
    end

    # This is mostly used for purging unmanaged resources
    it 'can delete an identifierless resource' do
      allow(auth0_tenant).to receive(:clients).and_return(build_list(:client_api,1,{
        client_id: 'abcd1234',
        client_metadata: {}
      }))
      expect(context).to receive(:notice).with(%r{\ADeleting '\*abcd1234'})
      expect(auth0_tenant).to receive(:delete_client).with('abcd1234')

      provider.delete(context, '*abcd1234')
    end
      
  end

  describe '#canonicalize(context,resources)' do
    before(:each) do
      allow(subject).to receive(:get_client_by_puppet_identifier).with(context,'foo').and_return(build(:client_api,client_is))
    end

    context 'when keep_extra_callbacks...' do
      context 'is true' do
        let(:client_is) { attributes_for(:client, {name: 'foo', callbacks: ['https://localhost:8080/callback']}) }
        let(:client_should) { client_is.merge(keep_extra_callbacks: true, callbacks: ['https://foo.com/callback']) }
        let(:client_canonical) { client_is.merge(callbacks: ['https://foo.com/callback','https://localhost:8080/callback']) }

        it 'leaves extra callbacks in place' do
          expect(context).to receive(:debug).with(%r{\AKeeping extra callbacks})
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end

      context 'is false' do
        let(:client_is) { attributes_for(:client, {name: 'foo', callbacks: ['https://localhost:8080/callback']}) }
        let(:client_should) { client_is.merge(keep_extra_callbacks: false, callbacks: ['https://foo.com/callback']) }
        let(:client_canonical) { client_is.merge(callbacks: ['https://foo.com/callback']) }

        it 'removes extra callbacks' do
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end
    end

    context 'when keep_extra_allowed_origins...' do
      context 'is true' do
        let(:client_is) { attributes_for(:client, {name: 'foo', allowed_origins: ['https://localhost:8080']}) }
        let(:client_should) { client_is.merge(keep_extra_allowed_origins: true, allowed_origins: ['https://foo.com']) }
        let(:client_canonical) { client_is.merge(allowed_origins: ['https://foo.com','https://localhost:8080']) }

        it 'leaves extra allowed_origins in place' do
          expect(context).to receive(:debug).with(%r{\AKeeping extra allowed_origins})
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end

      context 'is false' do
        let(:client_is) { attributes_for(:client, {name: 'foo', allowed_origins: ['https://localhost:8080']}) }
        let(:client_should) { client_is.merge(keep_extra_allowed_origins: false, allowed_origins: ['https://foo.com']) }
        let(:client_canonical) { client_is.merge(allowed_origins: ['https://foo.com']) }

        it 'removes extra allowed_origins' do
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end
    end

    context 'when keep_extra_web_origins...' do
      context 'is true' do
        let(:client_is) { attributes_for(:client, {name: 'foo', web_origins: ['https://localhost:8080']}) }
        let(:client_should) { client_is.merge(keep_extra_web_origins: true, web_origins: ['https://foo.com']) }
        let(:client_canonical) { client_is.merge(web_origins: ['https://foo.com','https://localhost:8080']) }

        it 'leaves extra web_origins in place' do
          expect(context).to receive(:debug).with(%r{\AKeeping extra web_origins})
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end

      context 'is false' do
        let(:client_is) { attributes_for(:client, {name: 'foo', web_origins: ['https://localhost:8080']}) }
        let(:client_should) { client_is.merge(keep_extra_web_origins: false, web_origins: ['https://foo.com']) }
        let(:client_canonical) { client_is.merge(web_origins: ['https://foo.com']) }

        it 'leaves extra web_origins in place' do
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end
    end

    context 'when keep_extra_allowed_logout_urls...' do
      context 'is true' do
        let(:client_is) { attributes_for(:client, {name: 'foo', allowed_logout_urls: ['https://localhost:8080/logged_out']}) }
        let(:client_should) { client_is.merge(keep_extra_allowed_logout_urls: true, allowed_logout_urls: ['https://foo.com/logged_out']) }
        let(:client_canonical) { client_is.merge(allowed_logout_urls: ['https://foo.com/logged_out','https://localhost:8080/logged_out']) }

        it 'leaves extra allowed_logout_urls in place' do
          expect(context).to receive(:debug).with(%r{\AKeeping extra allowed_logout_urls})
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end

      context 'is false' do
        let(:client_is) { attributes_for(:client, {name: 'foo', allowed_logout_urls: ['https://localhost:8080/logged_out']}) }
        let(:client_should) { client_is.merge(keep_extra_allowed_logout_urls: false, allowed_logout_urls: ['https://foo.com/logged_out']) }
        let(:client_canonical) { client_is.merge(allowed_logout_urls: ['https://foo.com/logged_out']) }

        it 'leaves extra allowed_logout_urls in place' do
          expect(provider.canonicalize(context,[build(:client_resource,client_should)])).to eq([build(:client_resource,client_canonical)])
        end
      end
    end
  end
end
