# @!visibility private
class zfs::install {

  if $::zfs::manage_repo {
    case $::osfamily {
      'RedHat': {

        file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux':
          ensure => 'present',
          source => 'puppet:///modules/zfs/RPM-GPG-KEY-zfsonlinux',
        }

        $os_version = $facts.dig('os', 'release', 'full').then |$s| {
          $s.regsubst(/^([0-9]+\.[0-9]+)/, '\1')
        }.lest || {
          fail('Could not get OS version')
        }

        yumrepo {
          default:
            enabled         => Integer(false),
            metadata_expire => '7d',
            gpgcheck        => Integer(true),
            gpgkey          => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux',
            require         => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux'],
            ;

          'zfs-dkms':
            enabled => Integer($::zfs::kmod_type == 'dkms' and !$::zfs::use_testing),
            descr   => "ZFS on Linux for ${os_version} - dkms",
            baseurl => "http://download.zfsonlinux.org/epel/${os_version}/\$basearch/",
            ;

          'zfs-kmod':
            enabled => Integer($::zfs::kmod_type == 'kmod' and !$::zfs::use_testing),
            descr   => "ZFS on Linux for ${os_version} - kmod",
            baseurl => "http://download.zfsonlinux.org/epel/${os_version}/kmod/\$basearch/",
            ;

          'zfs-source':
            enabled => Integer($::zfs::enable_source_repos and !$::zfs::use_testing),
            descr   => "ZFS on Linux for ${os_version} - source",
            baseurl => "http://download.zfsonlinux.org/epel/${os_version}/SRPMS/",
            ;

          'zfs-testing-dkms':
            enabled => Integer($::zfs::kmod_type == 'dkms' and $::zfs::use_testing),
            descr   => "ZFS on Linux for ${os_version} - dkms - testing",
            baseurl => "http://download.zfsonlinux.org/epel-testing/${os_version}/\$basearch/",
            ;

          'zfs-testing-kmod':
            enabled => Integer($::zfs::kmod_type == 'kmod' and $::zfs::use_testing),
            descr   => "ZFS on Linux for ${os_version} - kmod - testing",
            baseurl => "http://download.zfsonlinux.org/epel-testing/${os_version}/kmod/\$basearch/",
            ;

          'zfs-testing-source':
            enabled => Integer($::zfs::enable_source_repos and $::zfs::use_testing),
            descr   => "ZFS on Linux for ${os_version} - source - testing",
            baseurl => "http://download.zfsonlinux.org/epel-testing/${os_version}/SRPMS/",
            ;
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
