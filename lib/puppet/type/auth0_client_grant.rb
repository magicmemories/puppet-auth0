require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'auth0_client_grant',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: ['remote_resource'],
  title_patterns: [
    {
      pattern: %r{^(?<client_name>.+) -> (?<audience>.+)$},
      desc: "Where the client_name and the audience are provided with ` -> ` as a separator.",
    },
    {
      pattern: %r{^(?<client_name>.*)$},
      desc: "Where only the client_name is provided"
    }
  ],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    client_name:        {
      type:      'String',
      desc:      'The name of the client application receiving the grant.',
      behaviour: :namevar,
    },
    audience: {
      type: 'String',
      desc: 'The audience (identifier) of the resource server providing the grant.',
      behavior: :namevar,
    },
    scopes: {
      type: 'Array[String]',
      desc: 'The scopes being granted to the client application.',
      default: [],
    },
  },
  autorequire: {
    auth0_client: '$client_name',
    auth0_resource_server: '$audience',
  }
)
