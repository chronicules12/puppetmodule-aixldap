# aixldap
#
# A description of what this class does
#
# @summary Setup AD LDAP Authentication on AIX
#
# @example
#   include aixldap
#### NOTE: defaults are provided with module level hieradata
class aixldap (
  String $base_dn,
  String $bind_dn,
  String $bind_password,
  String $bind_password_crypted,
  String $ldapservers,
  String $pkg_src_path,
  Boolean $enable_ldap, # hiera
  Enum['running','stopped'] $service_ensure, # hiera
  Boolean $service_enable, #hiera
  Optional[String] $ssl_ca_cert_content,
  Optional[String] $ssl_ca_cert_source,
  String $ssl_ca_cert_label, # hiera
  String $ssl_ca_cert_file, # hiera
  String $user_map_file, # hiera
  Optional[String] $user_map_content,
  Optional[String] $user_map_source,
  String $group_map_file, # hiera
  Optional[String] $group_map_content,
  Optional[String] $group_map_source,
  String $ldap_cfg_file, #hiera
  Optional[Hash] $ldap_cfg_options, # hiera
  Enum['unix_auth','ldap_auth'] $auth_type, # hiera
  String $default_loc, # hiera
  String $domain, # hiera
  String $kdb_file, # hiera
  Optional[String] $kdb_password, # hiera
  Optional[String] $kdb_password_crypted, #hiera
  Optional[String] $kerb_realm, # hiera
  Enum['yes','SSL','TLS','NONE','no'] $use_ssl, # hiera
) {

  # Ensure Kerberos Realm is uppercase, default to "domain"
  $kerb_realm_real = upcase(pick($kerb_realm, $facts['networking']['domain']))

  # Ensure Local users authenticate locally
  # NOTE: root and virtuser will be handled elsewhere
  $local_users = split($facts['aix_local_users'], ' ')
  $local_users.each |$user| {
    if !defined(User[$user]) {
      user { $user:
        ensure         => 'present',
        ia_load_module => 'files',
        attributes     => [
          'SYSTEM=compat',
          'registry=files',
        ],
      }
    }
  }

  # Default Path
  Exec {
    path => '/usr/bin:/usr/sbin',
  }

  # Install Packages
  include aixldap::install

  # Configire
  include aixldap::configure

  # Service
  include aixldap::service

  Class['aixldap::install'] -> Class['aixldap::configure']

}
