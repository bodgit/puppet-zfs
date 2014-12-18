# zfs

Tested with Travis CI

[![Puppet Forge](http://img.shields.io/puppetforge/v/bodgit/zfs.svg)](https://forge.puppetlabs.com/bodgit/zfs)
[![Build Status](https://travis-ci.org/bodgit/puppet-zfs.svg?branch=master)](https://travis-ci.org/bodgit/puppet-zfs)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with zfs](#setup)
    * [What zfs affects](#what-zfs-affects)
    * [Beginning with zfs](#beginning-with-zfs)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module manages ZFS.

## Module Description

This module currently ensures that the ZFS packages available from [zfsonlinux.org](http://zfsonlinux.org) are installed.

## Setup

### What zfs affects

* The packages containing ZFS support.
* The services controlling any ZFS-related daemons.

### Beginning with zfs

```puppet
include ::zfs
```

## Usage

If you want to use something else to manage the zfs daemons, you can do:

```puppet
class { '::zfs':
  service_manage => false,
}
```

## Reference

### Classes

* zfs: Main class for installation and service management.
* zfs::install: Handles package installation.
* zfs::params: Different configuration data for different systems.
* zfs::service: Handles the zfs service.

### Parameters

####`package_dependencies`

An array of additional packages that should be installed alongside/before `package_name`.

####`package_ensure`

Intended state of the package providing zfs.

####`package_name`

The package name that provides zfs.

####`release_package_name`

The name of the package containing required package repository definitions.

####`release_package_source`

The source URL for downloading `release_package_name`.

####`service_enable`

Whether to enable the zfs service.

####`service_ensure`

Intended state of the zfs service.

####`service_manage`

Whether to manage the zfs service or not.

####`service_name`

The name of the zfs service.

## Limitations

This module has been built on and tested against Puppet 3.0 and higher.

The module has been tested on:

* RedHat Enterprise Linux 6/7
* Ubuntu 12.04/14.04
* Debian 7

It should also work on:

* Fedora 19/20 (need vagrant boxes for tests)
* Debian 6 (requires an updated DKMS package)

Testing on other platforms has been light and cannot be guaranteed.

## Authors

* Matt Dainty <matt@bodgit-n-scarper.com>
