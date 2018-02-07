# @api private
# Avoid modifying private classes.
# Configure AIXLDAP
class aixldap::configure (
  $use_ssl = $aixldap::use_ssl
) {
  assert_private('Please use aixldap main class')

  # Default ldap config settings
  $ldap_cfg_defaults = {
    ldapservers => $aixldap::serverlist,
    binddn      => $aixldap::bind_dn,
    bindpwd     => $aixldap::bind_password,
    basedn      => $aixldap::base_dn,
    ldapsslkeyf => $aixldap::kdb_file,
    authtype    => $aixldap::auth_type
  }

  if $aixldap::use_ssl {
    # SSL Certificate
    file { $aixldap::ssl_ca_cert_file:
      ensure  => 'file',
      content => $aixldap::ssl_ca_cert_content,
      source  => $aixldap::ssl_ca_cert_source,
      mode    => '0644',
      owner   => 'root',
      group   => 'system',
      notify  => Exec['trust-adldap-cert'],
    }

    $kdb_file = $aixldap::kdb_file
    $kdb_dir = dirname($kdb_file)
    $kdb_file_prefix = basename($kdb_file, '.kdb')
    exec { 'check-for-bad-keydb':
      command  => "mkdir -p ${kdb_dir}/keydb-sav$$ && mv ${kdb_dir}/${kdb_file_prefix}.* ${kdb_dir}/keydb-sav$$",
      unless   => "[ ! -f ${kdb_file} ] || gsk8capicmd_64 -cert -list -db \'${kdb_file}\' -pw \'${aixldap::kdb_password}\' -type cms",
      provider => 'shell',
      before   => [ Exec['create-keydb'], File[$aixldap::ssl_ca_cert_file] ],
    }

    exec { 'create-keydb':
      command => "gsk8capicmd_64 -keydb -create -db \'${kdb_file}\' -pw \'${aixldap::kdb_password}\' -type cms -stash -empty -strong",
      creates => $kdb_file,
      notify  => Exec['trust-adldap-cert'],
    }

    # NOTE: If the keydb file exists, but has the wrong password, this will fail
    exec { 'trust-adldap-cert':
      command     => "gsk8capicmd_64 -cert -add -db \'${kdb_file}\' -pw \'${aixldap::kdb_password}\' -type cms -file \'${aixldap::ssl_ca_cert_file}\' -trust enable -format ascii -label \'${aixldap::ssl_ca_cert_label}\'",
      refreshonly => true,
      require     => Exec['create-keydb'],
    }
  }

}
