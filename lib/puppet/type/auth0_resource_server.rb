require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'auth0_resource_server',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage Auth0 Resource Servers (APIs).
    EOS
  features: ['remote_resource'],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    identifier:        {
      type:      'String',
      desc:      'The identifier of the resource server.',
      behaviour: :namevar,
    },
    display_name: {
      type: 'Pattern[/^[^<>]+$/]',
      desc: 'The display name of the resource server.',
    },
    scopes: {
      type: 'Optional[Hash]',
      desc: 'No description given in Auth0 API documentation',
    },
    signing_alg: {
      type: "Optional[Enum['HS256','RS256']]",
      desc: "The algorithm used to sign tokens.",
    },
    signing_secret: {
      type: 'Optional[String]',
      desc: 'The secret used to sign tokens when using symmetric algorithms.',
    },
    allow_offline_access: {
      type: 'Optional[Boolean]',
      desc: 'Whether to allow issuance of refresh tokens for this entity.',
    },
    token_lifetime: {
      type: 'Optional[Integer]',
      desc: "The amount of time (in seconds) that the token will be valid after being issued.",
    },
    skip_consent: {
      type: 'Optional[Boolean]',
      desc: 'Whether this entity allows skipping consent prompt for verifiable first-party clients.',
    },
    # TODO: implement verificationLocation, options
  },
)
