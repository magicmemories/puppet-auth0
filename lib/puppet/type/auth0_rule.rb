require 'puppet/resource_api'
require 'puppetx/resource_api'

Puppet::ResourceApi.register_type(
  name: 'auth0_rule',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage Auth0 Rules
    EOS
  features: ['remote_resource'],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'Pattern[/^([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9 -]*[A-Za-z0-9])$/]',
      desc:      'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
    script: {
      type: 'String',
      desc: "A script that contains the rule's Javascript code.",
    },
    order: {
      type: 'Optional[Integer]',
      desc: "The rule's order in relation to other rules. A rule with a lower order than another rule executes first. If no order is provided it will automatically be one greater than the current maximum",
    },
    run_stage: {
      type: "Optional[Enum['login_success','login_failure','pre_authorize','user_registration','user_blocked']]",
      desc: "The stage at which the rule will be executed.",
      behavior: :init_only,
      default: 'login_success',
    },
    enabled: {
      type: 'Optional[Boolean]',
      desc: 'Whether this rule is enabled',
      default: true,
    }
  },
)
