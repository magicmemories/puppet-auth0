require 'spec_helper'
require 'puppet/type/auth0_client'

RSpec.describe 'the auth0_client type' do
  it 'loads' do
    expect(Puppet::Type.type(:auth0_client)).not_to be_nil
  end
end
