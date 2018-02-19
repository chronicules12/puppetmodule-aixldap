# aixldap
#
# A description of what this class does
#
# @summary Setup AD LDAP Authentication on AIX
#
# @example
#   include aixldap
#
# ### Params
# @param base_dn REQUIRED LDAP Base DN, such as dc=domain,dc=com
# @param bind_dn REQUIRED LDAP Bind User DN, User account to connect with to search LDAP Directory
# @param bind_password REQUIRED LDAP Bind User Password, Password for bind_dn account.
# @param bind_password_crypted REQUIRED Encrypted String of bind_password (for ldap.cfg), use `secldapclntd -e "password"`
#   on an AIX system with the LDAP Client packages installed to generate. It should look like:
#   `{DESv2}1AB38EC278 C2D186844D0501788FCBD` (NOTE: the space(s) can occur randomly)
# @param ldapservers REQUIRED Comma separated list of LDAP directory servers
# @param pkg_src_path Local Path on agent machine where installp packages will be located.
#   NOTE: Ensure the idsldap* packages are oslevel appropriate, or it may downgrade your TL.
#   (Default: `/tmp/ldap`)
# @param enable_ldap Whether or not to activate LDAP configuration (can be used for testing).
#   (Default: true)
# @param service_ensure secldapclntd service status (Default: `running`)
# @param service_enable Whether or not to start the `secldapclntd` service at boot time.
# @param use_ssl SSL Parameter, used in ldap.cfg and to be passed to mksecldap. NOTE: If this is enabled,
#   you should also specify ssl_ca_cert_content or ssl_ca_cert_source.
# @param ssl_ca_cert_label KDB Label for the SSL CA Certificate (Default `adldap`)
# @param ssl_ca_cert_file Filename of the SSL CA Certificate, which will be added as a trusted CA
#   to the KDB file. (Default: `/usr/lib/security/adldap.crt`)
# @param ssl_ca_cert_content RAW TEXT content of SSL CA Certificate, useful to put cert into hiera.
#   NOTE: REQUIRED IF `use_ssl` is `yes`, `SSL` or `TLS` (@see ssl_ca_cert_source)
# @param ssl_ca_cert_source Puppet File source to CA Cert file
#   NOTE: REQUIRED IF `use_ssl` is `yes`, `SSL` or `TLS` (@see ssl_ca_cert_content)
# @param user_map_file Filename of user attribute map (Default: `/etc/security/ldap/sfur2user.map`)
# @param user_map_content RAW TEXT content of the user attribute map, useful to put content into hiera.
#   (@see user_map_source)
# @param user_map_source Puppet File source for user attribute map
#   (@see user_map_content)
# @param group_map_file Filename of group attribute map (Default: `/etc/security/ldap/sfur2group.map`)
# @param group_map_content RAW TEXT content of the group attribute map, useful to put content into hiera.
#   (@see group_map_source)
# @param group_map_source Puppet File source for group attribute map
#   (@see group_map_content)
# @param ldap_cfg_file Filename for the ldap.cfg file (Default: `/etc/security/ldap/ldap.cfg`)
# @param ldap_cfg_options Hash of options for ldap.cfg file. This is a good place for additional options
#   that are not handled directly by this module. These options will be merged in hieradata and included
#   in the ldap.cfg.
#   Default:
#     aixldap::ldap_cfg_options:
#       serverschematype: sfur2
#       searchmode: ALL
#       ldapport: 389
#       ldapsslport: 636
#       userclasses: user,person,organizationalperson
#       groupclasses: group
# @param auth_type Authentication type, passed to mksecldap and part of ldap.cfg (Default: `unix_auth`)
# @param default_loc Default Entry Location in ldap.cfg and passed to mksecldap (Default: `ldap`)
# @param domain Domain name, (Default: (system's domain name))
# @param kerb_realm Kerberos Realm to authenticate with (Default: (uppercase system's domain name))
# @param kdb_file Filename of the SSL KDB file. (Default: /usr/lib/security/adldap.crt)
# @param kdb_password Password to "protect" KDB file (Default: ChangeMe!12345)
# @param kdb_password_crypted Encrypted KDB Password (for ldap.cfg). Use `secldapclntd -e "password"` on
#   AIX system to generate. (Default: `{DESv2}B264CA89603640B735E5EFA3EA4D68789D1F7F57F0 BC7E1`)
#
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
  String $ssl_ca_cert_label, # hiera
  String $ssl_ca_cert_file, # hiera
  Optional[String] $ssl_ca_cert_content,
  Optional[String] $ssl_ca_cert_source,
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
