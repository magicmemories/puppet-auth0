require_relative '../pops/adapters/auth0_adapter'

Puppet::Functions.create_function(:auth0_get_client_credentials) do
  dispatch :query do
    param 'String', :client_name
    param 'String', :auth0_client_id
    param 'String', :auth0_client_secret
    param 'String', :auth0_domain
    return_type 'Hash'
  end

  dispatch :implicit_query do
    param 'String', :client_name
    return_type 'Hash'
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