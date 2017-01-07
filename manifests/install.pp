# @!visibility private
class zfs::install {

  if $::zfs::manage_repo {
    case $::osfamily {
      'RedHat': {

        $_source = "http://download.zfsonlinux.org/epel/zfs-release.el${::operatingsystemmajrelease}.noarch.rpm"

        package { 'zfs-release':
          ensure   => present,
          provider => rpm,
          source   => $_source,
        }

        augeas { '/etc/yum.repos.d/zfs.repo/zfs/enabled':
          context => '/files/etc/yum.repos.d/zfs.repo/zfs',
          require => Package['zfs-release'],
          before  => Package[$::zfs::package_name],
        }

        augeas { '/etc/yum.repos.d/zfs.repo/zfs-kmod/enabled':
          context => '/files/etc/yum.repos.d/zfs.repo/zfs-kmod',
          require => Package['zfs-release'],
          before  => Package[$::zfs::package_name],
        }

        case $::zfs::kmod_type {
          'dkms': {
            Augeas['/etc/yum.repos.d/zfs.repo/zfs/enabled'] {
              changes => [
                'set enabled 1',
              ],
            }
            Augeas['/etc/yum.repos.d/zfs.repo/zfs-kmod/enabled'] {
              changes => [
                'set enabled 0',
              ],
            }
          }
          'kabi': {
            Augeas['/etc/yum.repos.d/zfs.repo/zfs/enabled'] {
              changes => [
                'set enabled 0',
              ],
            }
            Augeas['/etc/yum.repos.d/zfs.repo/zfs-kmod/enabled'] {
              changes => [
                'set enabled 1',
              ],
            }
          }
          default: {
            # noop
          }
        }
      }
      'Debian': {
        case $::operatingsystem {
          'Ubuntu': {
            ensure_packages(['python-software-properties'])

            ::apt::ppa { 'ppa:zfs-native/stable':
              require => Package['python-software-properties'],
              before  => Package[$::zfs::package_name],
            }
          }
          default: {
            # Not 100% sure this should be instantiated here (i.e. EPEL)
            class { '::apt::backports':
              before => Package[$::zfs::package_name],
            }
          }
        }
      }
      default: {
        # noop
      }
    }
  }

  # Handle these dependencies separately as they shouldn't be guarded by
  # `$zfs::manage_repo`
  case $::osfamily {
    'RedHat': {
      case $::zfs::kmod_type {
        'dkms': {
          ensure_packages(['kernel-devel'], {
            before => Package[$::zfs::package_name],
          })
        }
        default: {
          # noop
        }
      }
    }
    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          # noop
        }
        default: {
          ensure_packages(["linux-headers-${::kernelrelease}"], {
            before => Package[$::zfs::package_name],
          })
        }
      }
    }
    default: {
      # noop
    }
  }

  # These need to be done here so the kernel settings are present before the
  # package is installed and potentially loading the kernel module
  $config = delete_undef_values({
    'zfs_arc_max' => $::zfs::zfs_arc_max,
    'zfs_arc_min' => $::zfs::zfs_arc_min,
  })

  $config.each |$option,$value| {
    ::kmod::option { "zfs ${option}":
      module => 'zfs',
      option => $option,
      value  => $value,
      before => Package[$::zfs::package_name],
    }
  }

  package { $::zfs::package_name:
    ensure => present,
  }
}
