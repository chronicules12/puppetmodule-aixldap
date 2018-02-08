# @api private
# Avoid modifying private classes.
# Start AIXLDAP
class aixldap::service {

  service { 'secldapclntd':
    ensure => $aixldap::service_ensure,
    enable => $aixldap::service_enable,
  }

}
