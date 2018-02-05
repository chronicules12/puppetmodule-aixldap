# aixldap::install
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include aixldap::install
class aixldap::install (
  $pkg_source = aixldap::pkg_src_baseurl,
) {

  # Install GSKit8
  $gskit_pkgs = [ 'GSKit8.gskcrypt32.ppc.rte',
                  'GSKit8.gskcrypt64.ppc.rte',
                  'GSKit8.gskssl32.ppc.rte',
                  'GSKit8.gskssl64.ppc.rte',
                  'gsksa.rte',
                  'gskta.rte',
  ]

  $gskit_pkgs.each |$pkg| {
    package { $pkg:
      ensure => 'present',
      source => "${pkg_source}/gskit/${pkg}",
    }
  }

  # Install LDAP
  $kerb_pkgs = ['krb5.msg.en_US.client.rte',
                'krb5.lic',
                'krb5.client.samples',
                'krb5.client.rte',
  ]

  $kerb_pkgs.each |$pkg| {
    package { $pkg:
      ensure => 'present',
      source => "${pkg_source}/kerb/${pkg}",
    }
  }

  # Install LDAP
  $ldap_pkgs = ['idsldap.clt32bit62.rte',
                'idsldap.clt64bit62.rte',
                'idsldap.clt_max_crypto32bit62.rte',
                'idsldap.clt_max_crypto64bit62.rte',
                'idsldap.cltbase62.adt',
                'idsldap.cltbase62.rte',
                'idsldap.cltjava62.rte',
                'idsldap.clt32bit62.rte',
                'idsldap.clt64bit62.rte',
                'idsldap.cltbase62.rte',
  ]

  $ldap_pkgs.each |$pkg| {
    package { $pkg:
      ensure => 'present',
      source => "${pkg_source}/ldap/${pkg}",
    }
  }

}
