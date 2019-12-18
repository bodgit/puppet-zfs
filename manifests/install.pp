# @!visibility private
class zfs::install {

  if $::zfs::manage_repo {
    case $::osfamily {
      'RedHat': {
        file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux':
          ensure  => file,
          owner   => 0,
          group   => 0,
          mode    => '0644',
          content => file("${module_name}/RPM-GPG-KEY-zfsonlinux"),
        }

        $baseurl = 'http://download.zfsonlinux.org'
        $release = $::operatingsystemmajrelease ? {
          '7'     => $::operatingsystemrelease ? {
            /^7\.[012]/ => '7',
            default     => regsubst($::operatingsystemrelease, '^7\.(\d+).*$', '7.\1'),
          },
          default => $::operatingsystemmajrelease,
        }

        Yumrepo {
          ensure          => present,
          metadata_expire => '7d',
          gpgcheck        => 1,
          gpgkey          => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux',
          require         => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux'],
          before          => Package[$::zfs::package_name],
        }

        yumrepo { 'zfs':
          baseurl => "${baseurl}/epel/${release}/\$basearch/",
          descr   => "ZFS on Linux for EL${::operatingsystemmajrelease} - dkms",
          enabled => Integer($::zfs::kmod_type == 'dkms'),
        }

        yumrepo { 'zfs-kmod':
          baseurl => "${baseurl}/epel/${release}/kmod/\$basearch/",
          descr   => "ZFS on Linux for EL${::operatingsystemmajrelease} - kmod",
          enabled => Integer($::zfs::kmod_type == 'kmod'),
        }

        yumrepo { 'zfs-source':
          baseurl => "${baseurl}/epel/${release}/SRPMS/",
          descr   => "ZFS on Linux for EL${::operatingsystemmajrelease} - Source",
          enabled => 0,
        }

        yumrepo { 'zfs-testing':
          baseurl => "${baseurl}/epel-testing/${release}/\$basearch/",
          descr   => "ZFS on Linux for EL${::operatingsystemmajrelease} - dkms - Testing",
          enabled => 0,
        }

        yumrepo { 'zfs-testing-kmod':
          baseurl => "${baseurl}/epel-testing/${release}/kmod/\$basearch/",
          descr   => "ZFS on Linux for EL${::operatingsystemmajrelease} - kmod - Testing",
          enabled => 0,
        }

        yumrepo { 'zfs-testing-source':
          baseurl => "${baseurl}/epel-testing/${release}/SRPMS/",
          descr   => "ZFS on Linux for EL${::operatingsystemmajrelease} - Testing Source",
          enabled => 0,
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
          # Puppet doesn't like managing multiple versions of the same package.
          # By using the version in the name Yum will do the right thing
          ensure_packages(["kernel-devel-${::kernelrelease}"], {
            ensure => present,
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
          ensure_packages(["linux-headers-${::kernelrelease}", "linux-headers-${::architecture}"], {
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
