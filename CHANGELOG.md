## Release 2.0.0

### Summary

Major overhaul of module. This release drops support for Puppet 3.x and is
tested on a minimum of Puppet 4.4.0.

#### Features

- Add class and defined type for managing the ZFS Event Daemon.
- Add support for tuning the ARC.
- Add support for selecting between DKMS and kABI versions of the kernel
  modules.
- Add Debian 8 support.
- Add Ubuntu 16.04 support.
- Remove support for any OS not supported by the ZoL project, namely Fedora
  19/20 and Debian 6/7.
- Properly differentiate between systemd and traditional init-based systems.

#### Bugfixes

- Corrected any occurence of `archive.zfsonlinux.org` with
  `download.zfsonlinux.org`.

## Release 1.0.0

### Summary

Initial version.
