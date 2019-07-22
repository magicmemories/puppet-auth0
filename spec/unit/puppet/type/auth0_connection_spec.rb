require 'spec_helper'
require 'puppet/type/auth0_connection'

RSpec.describe 'the auth0_connection type' do
  it 'loads' do
    expect(Puppet::Type.type(:auth0_connection)).not_to be_nil
  end
end
