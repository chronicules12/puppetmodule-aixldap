# @api private
# Avoid modifying private classes.
# Configure AIXLDAP
class aixldap::configure {
  assert_private('Please use aixldap main class')

  if ($aixldap::use_ssl == 'yes' or $aixldap::use_ssl == 'SSL' or $aixldap::use_ssl == 'TLS') {
    # SSL Certificate
    file { $aixldap::ssl_ca_cert_file:
      ensure  => 'file',
      content => $aixldap::ssl_ca_cert_content,
      source  => $aixldap::ssl_ca_cert_source,
      mode    => '0644',
      owner   => 'root',
      group   => 'security',
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
      command     => "gsk8capicmd_64 -cert -add -db \'${kdb_file}\' -pw \'${aixldap::kdb_password}\' -type cms -file \'${aixldap::ssl_ca_cert_file}\' -trust enable -format ascii -label \'${aixldap::ssl_ca_cert_label}\'", # lint:ignore:140chars
      refreshonly => true,
      require     => Exec['create-keydb'],
      before      => Exec['mksecldap'],
      notify      => Service['secldapclntd'],
    }

    $ssl_options = "-n 636 -k \'${kdb_file}\' -w \'${aixldap::kdb_password}\'"
  } else {
    $ssl_options = '-n 389'
  }

  # run mksecldap - This seems to do a lot more than just setup the ldap.cfg, so we are going to execute it
  exec { 'mksecldap':
    command => "mksecldap -c -h \'${aixldap::ldapservers}\' -a \'${aixldap::bind_dn}\' -p \'${aixldap::bind_password}\' -d \'${aixldap::base_dn}\' ${ssl_options} -A ${aixldap::auth_type} -D ${aixldap::default_loc}", # lint:ignore:140chars
    creates => '/usr/lib/libibmldap.a',
    before  => File[$aixldap::ldap_cfg_file],
    timeout => 600,
  }


  # Default ldap config settings
  $ldap_cfg_defaults =  {
    ldapservers          => $aixldap::ldapservers,
    binddn               => $aixldap::bind_dn,
    bindpwd              => $aixldap::bind_password_crypted,
    basedn               => $aixldap::base_dn,
    ldapsslkeyf          => $aixldap::kdb_file,
    ldapsslkeypwd        => $aixldap::kdb_password_crypted,
    authtype             => $aixldap::auth_type,
    defaultentrylocation => $aixldap::default_loc,
    useSSL               => $aixldap::use_ssl,
    userattrmappath      => $aixldap::user_map_file,
    groupattrmappath     => $aixldap::group_map_file,
    userbasedn           => "CN=Users,${aixldap::base_dn}",
    groupbasedn          => "OU=Microsoft Exchange Security Groups,${aixldap::base_dn}",
    hostbasedn           => "OU=Disabled,OU=ENT-Services,${aixldap::base_dn}",
  }

  $ldap_cfgs = merge ($ldap_cfg_defaults, $aixldap::ldap_cfg_options)

  file { $aixldap::ldap_cfg_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'security',
    content => template('aixldap/ldap.cfg.erb'),
    notify  => Service['secldapclntd'],
  }

  file { $aixldap::user_map_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'security',
    mode    => '0644',
    content => $aixldap::user_map_content,
    source  => $aixldap::user_map_source,
    notify  => Service['secldapclntd'],
  }

  file { $aixldap::group_map_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'security',
    mode    => '0644',
    content => $aixldap::group_map_content,
    source  => $aixldap::group_map_source,
    notify  => Service['secldapclntd'],
  }

  # Kerberos Config (crutch exec)
  exec { 'mkkrb5clnt':
    command => "mkkrb5clnt  -l ${aixldap::ldapservers} -r ${aixldap::kerb_realm_real} -d ${aixldap::domain} -i LDAP -D",
    creates => '/etc/krb5/krb5.conf',
    require => Exec['mksecldap'],
  }

  if (aixldap::enable_ldap) {
    chsec { 'user-default-registry':
      ensure    => present,
      file      => '/etc/security/user',
      stanza    => 'default',
      attribute => 'registry',
      value     => 'KRB5LDAP',
      require   => Service['secldapclntd'],
    }

    chsec { 'user-default-SYSTEM':
      ensure    => present,
      file      => '/etc/security/user',
      stanza    => 'default',
      attribute => 'SYSTEM',
      value     => 'compat or KRB5LDAP',
      require   => Service['secldapclntd'],
    }

    # This will cause the user's attributes to be modified after defaults are changed
    Chsec['user-default-registry', 'user-default-SYSTEM'] -> User <| title != 'root' |>
  }

  # Ensure new local users are configured with SYSTEM=compat and registry=files
  ['user', 'admin'].each | String $stanza | {
    chsec { "mkuser.default-${stanza}-system":
      ensure    => present,
      file      => '/etc/security/mkuser.default',
      stanza    => $stanza,
      attribute => 'SYSTEM',
      value     => 'compat',
    }
    chsec { "mkuser.default-${stanza}-registry":
      ensure    => present,
      file      => '/etc/security/mkuser.default',
      stanza    => $stanza,
      attribute => 'registry',
      value     => 'files',
    }
  }

  # Lets just place this file - chsec is acting strange about this one
  file { '/etc/methods.cfg':
    ensure => 'file',
    source => 'puppet:///modules/aixldap/methods.cfg',
    owner  => 'root',
    group  => 'system',
    mode   => '0644',
  }

  # Manage /etc/netsvc.conf hosts line
  if $aixldap::netsvc_hosts {
    file_line { 'netsvc.conf-hosts':
      path  => '/etc/netsvc.conf',
      line  => "hosts = ${aixldap::netsvc_hosts}",
      match => '^hosts',
    }
  }

}
