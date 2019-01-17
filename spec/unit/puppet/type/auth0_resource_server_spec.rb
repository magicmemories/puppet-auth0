require 'spec_helper'
require 'puppet/type/auth0_resource_server'

RSpec.describe 'the auth0_resource_server type' do
  it 'loads' do
    expect(Puppet::Type.type(:auth0_resource_server)).not_to be_nil
  end
end
