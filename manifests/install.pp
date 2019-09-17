# @!visibility private
class zfs::install {

  if $::zfs::manage_repo {
    case $::osfamily {
      'RedHat': {

        yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux':
          ensure => 'present',
          source => 'puppet:///modules/zfs/RPM-GPG-KEY-zfsonlinux',
        }

        file { '/etc/yum.repos.d/zfs.repo':
          ensure  => 'file',
          content => epp('zfs/zfs.repo.epp', {
            os_version => $facts.dig('os', 'release', 'full').lest || {
              fail('Could not get OS version')
            },
          }),
          require => Yum::Gpgkey['/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux'],
        }

        augeas { '/etc/yum.repos.d/zfs.repo/zfs/enabled':
          context => '/files/etc/yum.repos.d/zfs.repo/zfs',
          require => File['/etc/yum.repos.d/zfs.repo'],
          before  => Package[$::zfs::package_name],
        }

        augeas { '/etc/yum.repos.d/zfs.repo/zfs-kmod/enabled':
          context => '/files/etc/yum.repos.d/zfs.repo/zfs-kmod',
          require => File['/etc/yum.repos.d/zfs.repo'],
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
            # noop
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
