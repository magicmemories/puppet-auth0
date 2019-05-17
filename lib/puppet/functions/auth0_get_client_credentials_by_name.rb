require_relative '../pops/adapters/auth0_adapter'

# Retrieves Client (Application) credentials from the Auth0 Management API by name.
Puppet::Functions.create_function(:auth0_get_client_credentials_by_name) do
  local_types do
    type 'Credentials = Struct[{client_id => String, client_secret => String}]'
  end

  # Gets client_id and client_secret for a client specified by name. 
  # @param client_name
  #   The display name of the client whose credentials will be retrieved
  # @param management_client_id
  #   The client_id that Puppet should use to access the Auth0 Management API
  # @param management_client_secret
  #   The client_secret that Puppet should use to access the Auth0 Management API
  # @param tenant_domain
  #   The Auth0 Domain (Tenant) that is being queried.
  # @return
  #   A Hash with two keys, 'client_id' and 'client_secret', containing
  #   the credentials for the requested client. Returns Undef if no client with
  #   the requested name could be found.
  # @example Retrieving client credentials.
  #   auth0_get_client_credentials_by_name('Example Application',$auth0_id,$auth0_secret,'example.auth0.com')
  dispatch :query do
    param 'String', :client_name
    param 'String', :management_client_id
    param 'String', :management_client_secret
    param 'String', :tenant_domain
    return_type 'Optional[Credentials]'
  end

  # Gets client_id and client_secret for a client specified by name. Retrieves credentials for the Auth0
  # Management API from Hiera under the keys 'auth0::management_client_id', 'auth0::management_client_secret'
  # and 'auth0::tenant_domain'.
  # @param client_name
  #   The name of the client whose credentials will be retrieved
  # @return
  #   A Hash with two keys, 'client_id' and 'client_secret', containing
  #   the credentials for the requested client. Returns Undef if no client with
  #   the requested name could be found.
  # @example Retrieving client credentials.
  #   auth0_get_client_credentials_by_name('Example Application')
  dispatch :implicit_query do
    param 'String', :client_name
    return_type 'Optional[Credentials]'
  end

  def query(client_name,id,secret,domain)
    api_client = Puppet::Pops::Adapters::Auth0Adapter.adapt(closure_scope.compiler).client(id,secret,domain)
    Puppet.info("Querying the Auth0 tenant at #{domain} for clients")
    
    found_clients = api_client.get_clients(fields: ['name','client_id','client_secret']).find_all {|c| c['name'] == client_name }
    Puppet.warning("Found #{found_clients.count} clients with the name #{client_name}, choosing the first one.") if found_clients.count > 1
    client = found_clients.first
    
    if client
      Puppet.debug("Got client data: #{client.inspect}")
      {'client_id' => client['client_id'], 'client_secret' => client['client_secret']}
    else
      Puppet.warning("No client named #{client_name} found.")
      nil
    end
  end

  def implicit_query(client_name)
    management_client_id = closure_scope.call_function('lookup','auth0::management_client_id')
    management_client_secret = closure_scope.call_function('lookup','auth0::management_client_secret')
    tenant_domain = closure_scope.call_function('lookup','auth0::tenant_domain')
    query(client_name,management_client_id,management_client_secret,tenant_domain)
  end
end