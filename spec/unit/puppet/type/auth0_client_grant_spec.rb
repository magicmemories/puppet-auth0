require 'spec_helper'
require 'puppet/type/auth0_client_grant'

RSpec.describe 'the auth0_client_grant type' do
  it 'loads' do
    expect(Puppet::Type.type(:auth0_client_grant)).not_to be_nil
  end
end
