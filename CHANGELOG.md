# Changelog

All notable changes to this project will be documented in this file.


## Release v0.2.0
* Support multiple userbasedn attributes (as an array to ldap_cfg_options)
* Updated default values for groupbasedn and hostbasedn
* Updated to PDK 1.6.0

## Release v0.1.3
* Fix metadata to point to larkit/chsec 0.1.4 (re-release of bwilcox/chsec with fixes)

## Release 0.1.2
* Fix a couple permissions related issues
* Add missing "4" on the end of the program_64 for NIS (like that matters)
* Fix /etc/security/mkuser.defaults is no longer replaced, specific attributes are set using chsec
* Remove workaround for chsec values with spaces, with chsec update to 0.1.4
* Updated /etc/netsvc.conf handling to be more advanced (allow overriding hosts line)

## Release 0.1.1

**Features**

**Bugfixes**
* Fix issue with Linux OS that doesn't have /bin/ksh

**Known Issues**


## Release 0.1.0

**Features**
* Initial Release

**Bugfixes**

**Known Issues**
