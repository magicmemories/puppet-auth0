# auth0

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with auth0](#setup)
3. [Usage - Managing Auth0](#usage---managing-auth0)
4. [Usage - Querying Auth0](#usage---querying-auth0)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module allows you to use Puppet to manage your Auth0 entities. It also provides the ability to query Auth0 and retrieve credentials
for use in Machine-to-Machine authentication flows (which you can then write to an applicaiton config file).

## Setup

In order for Puppet to access Auth0, you will need to create a Machine-to-Machine Application (aka a `non_interactive` client) inside Auth0,
and grant that client access to the Auth0 Management API. See [Machine-to-Machine Applications](https://auth0.com/docs/applications/machine-to-machine)
for details. 

This module treats each Auth0 tenant as a remote 'device', and uses the `puppet device` pattern for managing Auth0 resources. See the
[Puppet Device](https://puppet.com/docs/puppet/5.5/puppet_device.html) Documentation for details. The easiest way to get started is to use
the [puppetlabs-device_manager](https://forge.puppet.com/puppetlabs/device_manager) module, like so:

```puppet
device_manager { 'my-tenant.auth0.com':
  type        => 'auth0_tenant',
  credentials => {
    client_id     => $management_client_id,
    client_secret => $management_client_secret,
    domain        => 'my-tenant.auth0.com',
  },
}
```

The proxy node that is running `puppet device` will need to have the [auth0](https://rubygems.org/gems/auth0) gem installed. The easiest way to set this up is
to use the [`puppet_gem`](https://puppet.com/docs/puppet/5.5/types/package.html#package-provider-puppet_gem) provider for the `package` resource type:

```puppet
package { 'auth0':
  ensure   => present,
  provider => 'puppet_gem', 
}
```

To use the `auth0_get_client_credentials` function you will also need the auth0 gem installed on the Puppet Server. The easiest way to set this up is
with the [puppetlabs-puppetserver_gem](https://forge.puppet.com/puppetlabs/puppetserver_gem) module:

```puppet
package { 'auth0':
  ensure   => present,
  provider => 'puppetserver_gem', 
}
```
## Usage - Managing Auth0
These resource types can be used in a Device context to manage resources via the Auth0 Management API

### Creating a Client (Application)
```puppet
auth0_client { 'Example Application':
  description     => 'An example application to how how to use the auth0 Puppet module.',
  app_type        => 'non_interactive',
  callbacks       => ['https://app.example.com/callback'],
  allowed_origins => ['https://app.example.com'],
  web_origins     => ['https://app.example.com'],
}
```

### Creating a Resource Server (API)
```puppet
auth0_resource_server { 'https://api.example.com':
  display_name => "Example API",
  signing_alg  => "RS256",
  scopes       => { 
    'read:thingies'  => 'Get information about Thingies',
    'write:thingies' => 'Create, update and destroy Thingies',
    'read:doodads'   => 'Get information about Doodads',
  },
}
```

### Grant a Client access to a Resource Server with a Client Grant:
```puppet
auth0_client_grant { 'Give Example Application access to Example API':
  client_name => 'Example Application',
  audience    => 'https://api.example.com':,
  scopes      => [
    'read:thingies',
  ],
}

# Equivalent to above
auth0_client_grant { 'Example Application -> https://api.example.com':
  scopes => [
    'read:thingies',
  ],
}
```

### Define a Rule
```puppet
auth0_rule { 'Example Rule':
  script => file('profile/auth0/example_rule.js'),

}
```

## Usage - Querying Auth0

The `auth0_get_client_credentials` function can be used in an Agent or Apply context to
retrieve information from Auth0 when configuring your own servers and applications.

### Retrieve client credentials for a Machine-to-Machine application

#### With Management API credentials stored in Hiera
```yaml
auth0::management_client_id: 'abcdef12345678'
auth0::management_client_secret: 'abcedfg12313fgasdt235gargq345qrg4423425413543254535'
auth0::tenant_domain: 'example.auth0.com'
```
```puppet
$credentials = auth0_get_client_credentials('Example Application')
file { '/etc/example.conf':
  ensure  => present,
  content => epp('profile/example/example.conf.epp', {
    client_id     => $credentials['client_id'],
    client_secret => $credentials['client_secret'],
  }),
}
```

#### With Management API credentials provided explicitly
```puppet
$credentials = auth0_get_client_credentials(
  'Example Application',
  'abcdef12345678',
  'abcedfg12313fgasdt235gargq345qrg4423425413543254535',
  'example.auth0.com',
)
file { '/etc/example.conf':
  ensure  => present,
  content => epp('profile/example/example.conf.epp', {
    client_id     => $credentials['client_id'],
    client_secret => $credentials['client_secret'],
  }),
}
```

## Limitations
In order for Puppet to operate, every resource needs an identifier which meets two criteria:
1) It uniquely identifies a specific resource, consistently over time.
2) It can be specified by the sysadmin when creating the resource.

Most Auth0 resource types have a unique identifier which fails the second criterion: for example, the unique identifier for an
Auth0 Client resource should be its `client_id`, but you can't specify the client_id when creating a resource, so it can't be used as a
`namevar` in Puppet (and even if you could, you wouldn't really want to).

In order to work around this, we use the Client's `name` attribute for Puppet's `namevar`; however this means you should really treat your
Application and Rule names as immutable identifiers, even if Auth0 doesn't force you to.

`auth0_resource_server` resources don't have this problem, since the `identifier` (aka 'Audience') attribute of a Resource Server _is_
an immutable identifier that can be specified when creating the resource.

## Development

Development on this is still in the early stages.