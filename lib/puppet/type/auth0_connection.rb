require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'auth0_connection',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: ['remote_resource','canonicalize'],
  attributes: {
    ensure: {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type:      'Pattern[/^([\da-zA-Z]|[\da-zA-Z][\da-zA-Z-]{0,126}[\da-zA-Z])$/]',
      desc:      "The name of the connection. Must start and end with an alphanumeric character and can only contain alphanumeric characters and '-'. Max length 128.",
      behaviour: :namevar,
    },
    strategy: {
      type:      'String',
      desc:      'The type of the connection, related to the identity provider; common values include "ad" (Active Directory), "auth0" (Username-Password DB stored by Auth0), "google-oauth2", etc.',
      behaviour: :init_only,
    },
    options: {
      type: 'Optional[Hash]',
      desc: 'A hash of options used to configure the Connection; structure of the hash depends on the selected Strategy.', 
    },
    clients: {
      type: 'Optional[Array[String]]',
      desc: 'A list of client resource identifiers for which this connection is enabled.',
    },
    realms: {
      type: 'Optional[Array[String]]',
      desc: 'Defines the realms for which the connection will be used (ie: email domains). If the array is empty or the property is not specified, the connection name will be added as realm.',
    },
    keep_extra_clients: {
      type:      'Boolean',
      desc:      'If true, clients enabled for this connection in Auth0 but not in Puppet will be left in place. Only matters is clients property is specified; otherwise clients are always left alone.',
      behaviour: :parameter,
      default:   false,
    },
    keep_extra_options: {
      type:      'Boolean',
      desc:      'If true, options stored in Auth0 with no specified value in Puppet will be left as-is. Only matters if options property is specified; otherwise options is always left alone.',
      behaviour: :parameter,
      default:   false,
    },
  },
)
