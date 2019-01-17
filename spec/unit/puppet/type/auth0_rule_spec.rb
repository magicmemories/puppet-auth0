require 'spec_helper'
require 'puppet/type/auth0_rule'

RSpec.describe 'the auth0_rule type' do
  it 'loads' do
    expect(Puppet::Type.type(:auth0_rule)).not_to be_nil
  end
end
