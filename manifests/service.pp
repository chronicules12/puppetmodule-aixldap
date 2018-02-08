# @api private
# Avoid modifying private classes.
# Start AIXLDAP
class aixldap::service {

  service { 'secldapclntd':
    ensure   => $aixldap::service_ensure,
    enable   => $aixldap::service_enable,
    start    => '/usr/sbin/start-secldapclntd',
    stop     => '/usr/sbin/stop-secldapclntd',
    restart  => '/usr/sbin/restart-secldapclntd',
    status   => '/usr/sbin/ls-secldapclntd',
    provider => 'base',

  }

}
