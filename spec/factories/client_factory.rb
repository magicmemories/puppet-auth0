FactoryBot.define do
  factory :client, class:Hash do
    skip_create

    name { Faker::App.unique.name } 
    client_metadata { { 'puppet_resource_identifier' => name.gsub(/\W/,'_').gsub(/_+/,'_')[0,254] } }
    description { Faker::Lorem.paragraph_by_chars(140) }
    client_id { Faker::Internet.unique.password(32,32) }
    client_secret { Faker::Internet.password(64,64,true,true) }
    app_type { %w{spa non_interactive regular_web native}.sample }
    logo_uri { Faker::Internet.url }
    is_first_party { Faker::Boolean.boolean }
    oidc_conformant { Faker::Boolean.boolean }
    callbacks { Array.new(rand(3)) { Faker::Internet.url }.sort }
    allowed_origins { Array.new(rand(3)) { Faker::Internet.url }.sort }
    web_origins { Array.new(rand(3)) { Faker::Internet.url }.sort }
    client_aliases { [] }
    allowed_logout_urls { Array.new(rand(2)) { Faker::Internet.url }.sort }
    jwt_configuration { { "lifetime_in_seconds" => 36000, "alg" => %w{HS256 RS256}.sample } }
    sso { Faker::Boolean.boolean }
    sso_disabled { Faker::Boolean.boolean }
    token_endpoint_auth_method { %w{none client_secret_post client_secret_basic}.sample }
    grant_types { 
      [
        'implicit',
        'authorization_code',
        'password',
        'refresh_token',
        'http://auth0.com/oauth/grant-type/password-realm',
        'http://auth0.com/oauth/grant-type/mfa-oob',
        'http://auth0.com/oauth/grant-type/mfa-otp',
        'http://auth0.com/oauth/grant-type/mfa-recovery-code'
      ].sample(rand(8)+1).sort
    }

    factory :client_api do
      initialize_with { h = {}; attributes.each_pair {|k,v| h[k.to_s] = v}; h }
    end

    factory :client_resource do
      initialize_with do
        result = {}
        Puppet::Type::Auth0_client.allattrs.each do |prop|
          result[prop] = attributes[prop] unless attributes[prop].nil?
        end
        result[:display_name] = attributes[:name]
        result[:puppet_resource_identifier] = attributes.dig(:client_metadata,'puppet_resource_identifier')
        result[:jwt_alg] = attributes.dig(:jwt_configuration,'alg')
        result[:jwt_lifetime_in_seconds] = attributes.dig(:jwt_configuration,'lifetime_in_seconds')
        result[:ensure] = 'present'
        result
      end
    end
  end
end