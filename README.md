# zfs

Tested with Travis CI

[![Build Status](https://travis-ci.org/bodgit/puppet-zfs.svg?branch=master)](https://travis-ci.org/bodgit/puppet-zfs)
[![Coverage Status](https://coveralls.io/repos/bodgit/puppet-zfs/badge.svg?branch=master&service=github)](https://coveralls.io/github/bodgit/puppet-zfs?branch=master)
[![Puppet Forge](http://img.shields.io/puppetforge/v/bodgit/zfs.svg)](https://forge.puppetlabs.com/bodgit/zfs)
[![Dependency Status](https://gemnasium.com/bodgit/puppet-zfs.svg)](https://gemnasium.com/bodgit/puppet-zfs)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with zfs](#setup)
    * [What zfs affects](#what-zfs-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with zfs](#beginning-with-zfs)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module currently ensures that the ZFS packages available from
[zfsonlinux.org](http://zfsonlinux.org) are installed and configured.

RHEL/CentOS, Ubuntu and Debian are supported using Puppet 4.4.0 or later. On
RHEL/CentOS platforms there is support for installing the kABI-tracking kernel
modules as opposed to the default of DKMS-style kernel modules.

## Setup

### What zfs affects

This module will install kernel modules which utilises the DKMS framework to
accomplish this. This means kernel headers, toolchains, etc. will be installed.

### Setup Requirements

You will need pluginsync enabled. On RHEL/CentOS platforms you will need to
have access to the EPEL repository by using
[stahnma/epel](https://forge.puppet.com/stahnma/epel) or by other means.

### Beginning with zfs

In the very simplest case, you can just include the following:

```puppet
include ::zfs
```

## Usage

For example on RHEL/CentOS to instead install the kABI-tracking kernel modules
and tune the ARC, you can do:

```puppet
include ::epel

class { '::zfs':
  kmod_type   => 'kabi',
  zfs_arc_max => to_bytes('256 M'),
  zfs_arc_min => to_bytes('128 M'),
  require     => Class['::epel'],
}
```

To also install the ZFS Event Daemon (zed):

```puppet
include ::zfs
include ::zfs::zed
```

## Reference

The reference documentation is generated with
[puppet-strings](https://github.com/puppetlabs/puppet-strings) and the latest
version of the documentation is hosted at
[https://bodgit.github.io/puppet-zfs/](https://bodgit.github.io/puppet-zfs/).

## Limitations

This module has been built on and tested against Puppet 4.4.0 and higher.

The module has been tested on:

* RedHat Enterprise Linux 6/7
* Ubuntu 16.04
* Debian 8

It should also work on Ubuntu 12.04/14.04 however the quality of some aspects
of the packages make it difficult for the module to work properly.

## Development

The module has both [rspec-puppet](http://rspec-puppet.com) and
[beaker-rspec](https://github.com/puppetlabs/beaker-rspec) tests. Run them
with:

```
$ bundle exec rake test
$ PUPPET_INSTALL_TYPE=agent PUPPET_INSTALL_VERSION=x.y.z bundle exec rake beaker:<nodeset>
```

Please log issues or pull requests at
[github](https://github.com/bodgit/puppet-zfs).
