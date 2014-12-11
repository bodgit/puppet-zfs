#
class zfs::install {

  case $::osfamily {
    'RedHat': {
      package { $::zfs::release_package_name:
        ensure   => installed,
        provider => rpm,
        source   => $::zfs::release_package_source,
      }

      ensure_packages($::zfs::package_dependencies)

      package { $::zfs::package_name:
        ensure  => $::zfs::package_ensure,
        require => [
          Package[$::zfs::release_package_name],
          Package[$::zfs::package_dependencies],
        ],
      }

      if $::operatingsystem != 'Fedora' {
        include ::epel

        Class['::epel'] -> Package[$::zfs::package_name]
      }
    }
    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          include ::apt

          ensure_packages(['python-software-properties'])

          apt::ppa { 'ppa:zfs-native/stable':
            require => Package['python-software-properties'],
          }

          package { $::zfs::package_name:
            require => Apt::Ppa['ppa:zfs-native/stable'],
          }
        }
        default: {
          package { $::zfs::release_package_name:
            ensure   => installed,
            provider => dpkg,
            source   => $::zfs::release_package_source,
          }

          ensure_packages($::zfs::package_dependencies)

          package { $::zfs::package_name:
            ensure  => $::zfs::package_ensure,
            require => [
              Package[$::zfs::release_package_name],
              Package[$::zfs::package_dependencies],
            ],
          }
        }
      }
    }
    default: {}
  }
}
