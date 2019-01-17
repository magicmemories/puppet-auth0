require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'auth0_connection',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: [],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'String',
      desc:      'The name of the connection you want to manage.',
      behaviour: :namevar,
    },
  },
)
