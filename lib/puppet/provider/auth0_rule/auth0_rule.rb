require 'puppet/resource_api/simple_provider'
require_relative '../../util/network_device/auth0_tenant/device'

# Implementation for the auth0_rule type using the Resource API.
class Puppet::Provider::Auth0Rule::Auth0Rule < Puppet::ResourceApi::SimpleProvider
  def get(context)
    rules(context).map do |rule|
      {
        ensure: 'present',
        name: rule['name'],
        script: rule['script'],
        order: rule['order'],
        enabled: rule['enabled'],
        run_stage: rule['stage'],
      }
    end
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    context.device.create_rule(name,should[:script],should[:order],should[:enabled],should[:run_stage])
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    id = get_rule_id_by_name(context,name)
    fields_to_update = {
      'script'  => should[:script],
      'order'   => should[:order],
      'enabled' => should[:enabled],
    }.compact
    context.device.update_rule(id,fields_to_update)
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    id = get_rule_id_by_name(context,name)
    context.device.delete_rule(id)
  end

  private
  def rules(context)
    @__rules ||= context.device.get_rules
  end

  def get_rule_id_by_name(context,name)
    found_rules = rules(context).find_all {|r| r['name'] == name }
    context.warning("Found #{found_rules.count} rules with name #{name}, picking the first one.") if found_rules.count > 1
    found_rules.dig(0,'id')
  end
end
