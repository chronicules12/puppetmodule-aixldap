#!/bin/ksh
# This will get a list of local users that are not a common system user.
# These local users will have some attributes set to ensure they authenticate locally.
PATH='/usr/bin:/usr/sbin'
export PATH
if [ `uname` == 'AIX' ]; then
    sysusers="root bin daemon sys adm uucp nobody lpd lp invscout snapp nuucp ipsec pconsole esaadmin sshd srvproxy virtuser"
    tmpstring=""
    for i in $sysusers; do
        idstring="^$i\$"
        tmpstring="$tmpstring|$idstring"
    done
    exclude=$(echo "$tmpstring" | cut -c 2-)

    ## 'users' are non-standard users discovered, could be appuser/realuser
    users=$(lsuser ALL | awk '{print $1}' |egrep -v "$exclude" | xargs echo)
    echo "aix_local_users=${users}"
fi
