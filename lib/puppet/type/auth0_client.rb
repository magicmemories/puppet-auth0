require 'puppet/resource_api'
require 'puppetx/resource_api'

Puppet::ResourceApi.register_type(
  name: 'auth0_client',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage Auth0 Client (Application) resources.
    EOS
  features: ['remote_resource','canonicalize'],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    puppet_resource_identifier: {
      type: 'String[0,255]',
      desc: 'A unique identifier for this client; stored in the client_metadata hash under the key "puppet_resource_identifier".',
      behavior: :namevar,
    },
    display_name: {
      type: 'Pattern[/^[^<>]+$/]',
      desc: 'The name of the client (Application). Does not allow "<" or ">".',
    },
    description: {
      type: 'Optional[String[0,140]]',
      desc: 'Free text description of the purpose of this client.',
    },
    logo_uri: {
      type: 'Optional[String]',
      desc: 'The URL of the client logo (recommended size: 150x150).',
    },
    callbacks: {
      type: 'Optional[Array[String]]',
      desc: 'A set of URLs that are valid to call back from Auth0 when authenticating users. To remove all callbacks you must specify an empty array; leaving this undefined will leave existing callbacks untouched.',
    },
    keep_extra_callbacks: {
      type: 'Boolean',
      desc: 'If true, callbacks set in Auth0 but not in puppet will be left in place.',
      default: false,
      behavior: :parameter,
    },
    allowed_origins: {
      type: 'Optional[Array[String]]',
      desc: 'A set of URLs that represent valid origins for CORS.',
    },
    keep_extra_allowed_origins: {
      type: 'Boolean',
      desc: 'If true, allowed_origins set in Auth0 but not in puppet will be left in place.',
      default: false,
      behavior: :parameter,
    },
    web_origins: {
      type: 'Optional[Array[String]]',
      desc: 'A set of URLs that represents valid web origins for use with web message response mode.',
    },
    keep_extra_web_origins: {
      type: 'Boolean',
      desc: 'If true, web_origins set in Auth0 but not in puppet will be left in place.',
      default: false,
      behavior: :parameter,
    },
    client_aliases: {
      type: 'Optional[Array[String]]',
      desc: 'List of audiences for SAML protocol.',
    },
    #allowed_clients: {
    #  type: 'Optional[Array[String]]',
    #  desc: 'Ids of clients that will be allowed to perform delegation requests. By default all your clients will be allowed.',
    #},
    allowed_logout_urls: {
      type: 'Optional[Array[String]]',
      desc: 'A set of URLs that are valid to redirect to after logout from Auth0',
    },
    keep_extra_allowed_logout_urls: {
      type: 'Boolean',
      desc: 'If true, allowed_logout_urls set in Auth0 but not in puppet will be left in place.',
      default: false,
      behavior: :parameter,
    },
    grant_types: {
      type: 'Optional[Array[String]]',
      desc: 'A set of grant types that the client is authorized to use',
    },
    token_endpoint_auth_method: {
      type: "Optional[Enum['none','client_secret_post','client_secret_basic']]",
      desc: 'Defines the requested authentication methods for the token endpoint.',
    },
    app_type: {
      type: 'Optional[String]',
      desc: 'The type of application this client represents. Common values include "native", "spa" (single-page-application), "non_interactive" (Machine-to-Machine) and "regular_web".',
    },
    oidc_conformant: {
      type: 'Optional[Boolean]',
      desc: 'Whether this client will conform to string OIDC specifications.',
    },
    jwt_lifetime_in_seconds: {
      type: 'Optional[Integer]',
      desc: 'The amount of time (in seconds) that the token will be valid after being issued.',
    },
    jwt_alg: {
      type: "Optional[Enum['HS256','RS256']]",
      desc: 'The algorithm used to sign the JsonWebToken',
    },
    sso: {
      type: 'Optional[Boolean]',
      desc: 'Whether to use Auth0 instead of the IdP to do single sign on.',
    },
    sso_disabled: {
      type: 'Optional[Boolean]',
      desc: 'Whether to disable Single Sign On',
    },
    client_id: {
      type: 'String',
      desc: 'Auth0 server-side unique identifier for Client.',
      behavior: :read_only,
    }
    # TODO: Support allowed_clients, jwt_scopes, encryption_key, cross_origin_auth, cross_origin_loc, custom_login_page_on, custom_login_page, custom_login_page_preview, form_template, is_heroku_app, addons, client_metadata, and mobile parameters.
  },
)
