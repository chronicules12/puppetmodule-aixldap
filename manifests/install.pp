# @api private
# Avoid modifying private classes.
#
# aixldap::install
#
# Install the required packages for AIX LDAP Authentication.
#
# @summary Install the required packages for AIX LDAP Authentication.
#
class aixldap::install {

  # Install GSKit8, KRB5 and LDAP
  $packages = [ 'GSKit8.gskcrypt32.ppc.rte',
                'GSKit8.gskcrypt64.ppc.rte',
                'GSKit8.gskssl32.ppc.rte',
                'GSKit8.gskssl64.ppc.rte',
                'gsksa.rte',
                'gskta.rte',
                'krb5.msg.en_US.client.rte',
                'krb5.lic',
                'krb5.client.samples',
                'krb5.client.rte',
                'idsldap.clt32bit62.rte',
                'idsldap.clt64bit62.rte',
                'idsldap.clt_max_crypto32bit62.rte',
                'idsldap.clt_max_crypto64bit62.rte',
                'idsldap.cltbase62.adt',
                'idsldap.cltbase62.rte',
                'idsldap.cltjava62.rte',
  ]

  # Naughty Install
  $pkg_list = $packages.expand(' ')
  exec {'install-aixldap-packages-all-at-once':
    command => "installp -acNgXY -d ${aixldap::pkg_src_path} ${pkg_list}",
    unless  => "lslpp -lc ${pkg_list}",
  }

  package { $packages:
    ensure => 'present',
    source => ${aixldap::pkg_src_path},
  }

}
