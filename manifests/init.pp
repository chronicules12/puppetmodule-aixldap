# aixldap
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include aixldap
#### NOTE: defaults are provided with module level hieradata
class aixldap (
  String $base_dn,
  String $bind_dn,
  String $bind_pwd,
  Variant[Array[String],String] $serverlist,
  String $pkg_src_baseurl,
  String $auth_type,
  String $default_loc,
  String $domain,
  String $kerb_realm,
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

  # Install Packages
  include aixldap::install

  # Configire
  include aixldap::configure

}
