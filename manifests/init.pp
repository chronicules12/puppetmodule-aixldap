# aixldap
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include aixldap
class aixldap (
  String $base_dn,
  String $bind_dn,
  String $bind_pwd,
  Variant[Array[String],String] $serverlist,
  String $pkg_src_baseurl = 'https://artifactory.davita.com/aix_ldap/',
  String $auth_type = 'unix_auth',
  String $default_loc = 'ldap',
  String $domain = $facts['networking']['domain'],
  String $kerb_realm = upcase($facts['networking']['domain']),
) {

  # Ensure Local users authenticate locally
  # NOTE: root and virtuser will be handled elsewhere
  $local_users = split($facts['aix_local_users'], ' ')
  $local_users.each |$user| {
    if !defined(User[$user]) {
      user { $user:
        ensure     => 'present',
        attributes => [
          'SYSTEM=compat',
          'registry=files',
        ],
      }
    }
  }

  # Install
  include aixldap::install

  # Configire
  include aixldap::configure

}
