# aixldap
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include aixldap
class aixldap (
) {

  # Ensure Local users authenticate locally
  # NOTE: root and virtuser will be handled elsewhere
  $local_users = split($facts['aix_local_users'], ' ')
  user { $local_users:
    ensure     => 'present',
    attributes => {
      'SYSTEM'   => 'compat',
      'registry' => 'files',
    },
  }




}
