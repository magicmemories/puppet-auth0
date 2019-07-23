require_relative '../pops/adapters/auth0_adapter'

# Retrieves Client (Application) credentials from the Auth0 Management API.
# @note 
#   This function requires the `read:client_keys` scope of Auth0's Management API.
Puppet::Functions.create_function(:auth0_get_client_credentials) do
  local_types do
    type 'Credentials = Struct[{client_id => String, client_secret => String}]'
  end

  # Gets client_id and client_secret for a client specified by its
  # puppet_resource_identifier. 
  # @param puppet_resource_identifier
  #   The puppet_resource_identifier of the client whose credentials will be
  #   retrieved.
  # @param management_client_id
  #   The client_id that Puppet should use to access the Auth0 Management API
  # @param management_client_secret
  #   The client_secret that Puppet should use to access the Auth0 Management API
  # @param tenant_domain
  #   The Auth0 Domain (Tenant) that is being queried.
  # @return
  #   A Hash with two keys, 'client_id' and 'client_secret', containing
  #   the credentials for the requested client. Returns Undef if no client with
  #   the requested puppet_resource_identifier could be found.
  # @example Retrieving client credentials.
  #   auth0_get_client_credentials('example_application',$auth0_id,$auth0_secret,'example.auth0.com')
  dispatch :query do
    param 'String', :puppet_resource_identifier
    param 'String', :management_client_id
    param 'String', :management_client_secret
    param 'String', :tenant_domain
    return_type 'Optional[Credentials]'
  end

  # Gets client_id and client_secret for a client specified by its
  # puppet_resource_identifier. Retrieves credentials for the Auth0 Management
  # API from Hiera under the keys 'auth0::management_client_id',
  # 'auth0::management_client_secret' and 'auth0::tenant_domain'.
  # @param puppet_resource_identifier
  #   The name of the client whose credentials will be retrieved
  # @return
  #   A Hash with two keys, 'client_id' and 'client_secret', containing
  #   the credentials for the requested client. Returns Undef if no client with
  #   the requested puppet_resource_identifier could be found.
  # @example Retrieving client credentials.
  #   auth0_get_client_credentials('Example Application')
  dispatch :implicit_query do
    param 'String', :puppet_resource_identifier
    return_type 'Optional[Credentials]'
  end

  def query(puppet_resource_identifier,id,secret,domain)
    api_client = Puppet::Pops::Adapters::Auth0Adapter.adapt(closure_scope.compiler).client(id,secret,domain)
    Puppet.info("Querying the Auth0 tenant at #{domain} for clients")
    
    all_clients = api_client.get_clients(fields: ['client_metadata','client_id','client_secret'])
    found_clients = all_clients.find_all {|c| c.dig('client_metadata','puppet_resource_identifier') == puppet_resource_identifier }
    Puppet.warning("Found #{found_clients.count} clients whose puppet_resource_identifier is  #{puppet_resource_identifier}, choosing the first one.") if found_clients.count > 1
    client = found_clients.first
    
    if client
      Puppet.debug("Got client data: #{client.inspect}")
      {'client_id' => client['client_id'], 'client_secret' => client['client_secret']}
    else
      Puppet.warning("No client with the puppet_resource_identifier #{puppet_resource_identifier} found.")
      nil
    end
  end

  def implicit_query(puppet_resource_identifier)
    management_client_id = closure_scope.call_function('lookup','auth0::management_client_id')
    management_client_secret = closure_scope.call_function('lookup','auth0::management_client_secret')
    tenant_domain = closure_scope.call_function('lookup','auth0::tenant_domain')
    query(puppet_resource_identifier,management_client_id,management_client_secret,tenant_domain)
  end
end