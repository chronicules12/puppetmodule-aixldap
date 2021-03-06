# aixldap

[![Build Status](https://travis-ci.org/LarkIT/puppetmodule-aixldap.svg?branch=master)](https://travis-ci.org/LarkIT/puppetmodule-aixldap)
[![Puppet Forge](https://img.shields.io/puppetforge/v/larkit/aixldap.svg)](https://forge.puppet.com/larkit/aixldap)
[![Puppet Forge](https://img.shields.io/puppetforge/dt/larkit/aixldap.svg)](https://forge.puppet.com/larkit/aixldap)
[![Puppet Forge](https://img.shields.io/puppetforge/e/larkit/aixldap.svg)](https://forge.puppet.com/larkit/aixldap)
[![Puppet Forge](https://img.shields.io/puppetforge/f/larkit/aixldap.svg)](https://forge.puppet.com/larkit/aixldap)

* Source: https://github.com/LarkIT/puppetmodule-aixldap
* Documentation: https://larkit.github.io/puppetmodule-aixldap/
* Forge: https://forge.puppet.com/larkit/aixldap

This module will setup your AIX system to use AD LDAP Authentication.

This module probably over-steps the concept of "do one thing" pretty far. I contend that the GSKit8 stuff and management of the SSL KDB file probably belongs in its own module, but for now its a self contained "setup my ldap authentication" module. This module also attempts to make sure that local accounts will have `SYSTEM=compat registry=files` added to them so that they still work.

## Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with aixldap](#setup)
    * [What aixldap affects](#what-aixldap-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with aixldap](#beginning-with-aixldap)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

The aixldap module will install the necessary packages and configure Active Directory (AD) Kerberos LDAP authentication.

## Setup

### What aixldap affects

* Installs idsldap.clnt, krb5 and GSKit8 packages
* Setup a kdb file to trust the AD CA cert for SSL
* Configure ldap (mksecldap) and set some custom parameters in ldap.cfg.
* Optionally configure custom user_map and group_map files.
* Configure Kerberos (mkkrb5clnt)
* Optionally enable (activate) LDAP authentication.
* Configure /etc/security/mkuser.default, /etc/methods.cfg and /etc/netsvc.conf appropriate for LDAP authentication (making local users local)
* Start LDAP services (secldapclntd)
* Ensures that local users have appropriate attributes set to work after LDAP authentication is enabled.

### Setup Requirements

* You must have the LDAP packages hosted somewhere accessible to the AIX system. Currently the default location to stage them is `/tmp/pkg`. You may want to stage them at provisioning time or make them available over NFS / autofs ([puppet-autofs](https://forge.puppet.com/puppet/autofs)).
* You should also *know* the LDAP directory you are binding to. You will likely need several details that are not readily available to a casual user.
* You will need a BindDN and Password for searching the directory (service account). - NOTE: This may not be strictly required in all cases, but this code requires it.
* If your directory uses SSL, you will need the CA Certificate, as LDAP is very picky about SSL.
* Example code to use a "temporary" NFS mount:

```puppet
# AIX Package Repo - This content is not specifically profile material
class profile::aix_pkg_repo (
  String $repo_mount,
  String $repo_path = '/var/run/pkg_repo',
)
  # Create mountpoint
  file { $repo_path:
    ensure => directory,
    before => Mount[$repo_path],
  }

  # Create filesystem mount reference (do not mount)
  mount { $repo_path:
    ensure  => 'unmounted',
    atboot  => false,
    device  => $repo_mount,
    fstype  => 'nfs',
    options => 'ro,fg,intr'
  }

  # List dependencies on this repo_path
  $pkg_repo_dependencies = [
    Exec['install-aixldap-packages-all-at-once'],
    #Package['rpm.rte'],
  ]

  # Make sure the dependencies process before the mountpoint is unmounted again.
  $pkg_repo_dependencies.each | $res | {
    # This may seem backwards, but remember the "Mount[$repo_path]" will actually unmount
    $res -> Mount[$repo_path]
  }

  # This will *mount* the pkg_repo before changing the dependent resources
  transition { "mount ${repo_path}":
    resource   => Mount[$repo_path],
    attributes => { ensure => 'mounted' },
    prior_to   => $pkg_repo_dependencies,
  }
}
```

### Beginning with aixldap

At the most basic level, this module is going to require a few values in hieradata (or in the class call):

* basedn - usually something like dc=DOMAIN,dc=COM
* binddn - account used to bind for ldap searches (currently required)
* bindpw - password for bind account
* bindpw_crypted (use secldapclntd -e "thepassword")
* ldapservers - comma separated list of ldapservers

If you want to use SSL, you will also need to provide:

* use_ssl: 'yes' (if you use hiera, make sure yes is in quotes or it will come back as the boolean true)
* ssl_ca_cert_content (or ssl_ca_cert_file)

There are many other parameters that you can set to customize other parts. Please refer to the [manifests/init.pp] code for details.

## Usage

AIX base profile:

```puppet
# Specify this as early as possible in your AIX Base profile so that ANY users created will have this in scope.
User {
  ia_load_module => 'files',
  attributes     => ['SYSTEM=compat','registry=files']
}

include aixldap
```

Hiera:

```yaml
aixldap::basedn: dc=mydomain,dc=com
aixldap::binddn: cn=myldapuser,ou=People,dc=mydomain,dc=com
aixldap::bindpw: ENC.........please_use_eyaml!
aixldap::bindpw_crypted: (use secldapclntd -e 'bind_password') ... and maybe use eymal too?
aixldap::ldapservers: adserver.sub.domain.com
```

Special Note: If you need to have multiple userbasedn values, you
can specify them as an array like so:

```yaml
aixldap::ldap_cfg_options:
  userbasedn:
    - OU=Users,OU=UnixTeam,dc=mydomain,dc=com
    - OU=ServiceAccounts,dc=mydomain,dc=com
```

## Reference

See https://larkit.github.io/puppetmodule-aixldap/

## Limitations

This is only compatible with AIX. We have only tested it on AIX 7.1 (TL2 and TL4) and AIX 7.2 (TL1). NOTE that the idsldap* packages are TL specific. Check your `oslevel -s` output (`facter os.release.full`)

## Development

Feel free to fork/cone and submit pull requests.

## Release Notes

See [CHANGELOG.md](CHANGELOG.md).
