# Changelog

All notable changes to this project will be documented in this file.

## Release 0.3.5
Bugfix release to fix `auth0_get_client_credentials` function broken by previous bugfix.

## Release 0.3.4
Bugfix release to add missing pagination to requests made for `auth0_get_client_credentials` function.

## Release 0.3.3
Bugfix release to add missing pagination to requests made for `auth0_get_client_credentials_by_name` function.

## Release 0.3.2
Bugfix to allow this to work with both Puppet 5 (Ruby 2.4) and 6 (Ruby 2.5+)

## Release 0.3.1
Bugfix Release, fixes patching auth0 clients with JWT token information.

## Release 0.3.0
This release adds handling of rate-limit errors and request pagination.

## Release 0.2.4
This release improves debug output.

## Release 0.2.3
This release adds additional debug output and error handling.

## Release 0.2.2
This release adds some missing documentation.

## Release 0.2.1
This release adds some missing documentation.

## Release 0.2.0
New features:

* Added the ability to manage Auth0 Connections

## Release 0.1.3
Bugfix Release

* Ignore the order of scopes in the auth0_client_grant resource.

## Release 0.1.2
Bugfix Release

* Don't include the Identifier in the request body when updating a Resource Server.

## Release 0.1.1
Bugfix Release

* auth0_client_grant properly outputs a warning rather than raising an
  exception, when a client has no puppet_resource_identifier.

## Release 0.1.0

Initial Release