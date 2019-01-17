require_relative '../pops/adapters/auth0_adapter'

Puppet::Functions.create_function(:auth0_get_client_credentials) do
  local_types do
    type 'Credentials = Struct[{client_id => String, client_secret => String}]'
  end

  # Gets client_id and client_secret for a client specified by name in a specific tenant.
  # @param client_name
  #   The name of the client whose credentials will be retrieved
  # @param auth0_client_id
  #   The client_id that Puppet should use to access the Auth0 Management API
  # @param auth0_client_secret
  #   The client_secret that Puppet should use to access the Auth0 Management API
  # @param auth0_domain
  #   The Auth0 Domain (Tenant) that is being queried.
  # @return
  #   Returns a Hash with two keys, 'client_id' and 'client_secret', containing
  #   the credentials for the requested client. Returns Undef if no client with
  #   the requested name could be found.
  # @example
  #   Retrieving client credentials.
  #   auth0_get_client_credentials('Example Application',$auth0_id,$auth0_secret,'example.auth0.com')
  dispatch :query do
    param 'String', :client_name
    param 'String', :auth0_client_id
    param 'String', :auth0_client_secret
    param 'String', :auth0_domain
    return_type 'Optional[Credentials]'
  end

  # Gets client_id and client_secret for a client specified by name. Retrieves credentials for the Auth0
  # Management API from Hiera under the keys 'auth0::management_client_id', 'auth0::management_client_secret'
  # and 'auth0::management_domain'.
  # @param client_name
  #   The name of the client whose credentials will be retrieved
  # @return
  #   Returns a Hash with two keys, 'client_id' and 'client_secret', containing
  #   the credentials for the requested client. Returns Undef if no client with
  #   the requested name could be found.
  # @example
  #   Retrieving client credentials.
  #   auth0_get_client_credentials('Example Application',$auth0_id,$auth0_secret,'example.auth0.com')
  dispatch :implicit_query do
    param 'String', :client_name
    return_type 'Optional[Credentials]'
  end

  def query(client_name,id,secret,domain)
    api_client = Puppet::Pops::Adapters::Auth0Adapter.adapt(closure_scope.compiler).client(id,secret,domain)
    Puppet.info("Querying the Auth0 client")
    
    found_clients = api_client.get_clients(fields: ['name','client_id','client_secret']).find_all {|c| c['name'] == client_name }
    context.warning("Found #{found_clients.count} clients with the name #{name}, choosing the first one.") if found_clients.count > 1
    client = found_clients.first
    
    if client
      Puppet.debug("Got client data: #{client.inspect}")
      {'client_id' => client['client_id'], 'client_secret' => client['client_secret']}
    else
      context.warning("No client named #{client_name} found.")
      nil
    end
  end

  def implicit_query(client_name)
    auth0_client_id = call_function('lookup','auth0::management_client_id')
    auth0_client_secret = call_function('lookup','auth0::management_client_secret')
    auth0_domain = call_function('lookup','auth0::managment_domain')
    query(client_name,auth0_client_id,auth0_client_secret,auth0_domain)
  end
end