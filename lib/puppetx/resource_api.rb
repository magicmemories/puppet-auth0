require 'puppet/resource_api'

# @see https://github.com/puppetlabs/puppet-resource_api/issues/179
class Puppet::ResourceApi::ResourceShim
  def to_hash
    values.dup
  end
end