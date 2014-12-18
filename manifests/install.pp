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
      include ::apt

      case $::operatingsystem {
        'Ubuntu': {

          ensure_packages(['python-software-properties'])

          apt::ppa { 'ppa:zfs-native/stable':
            require => Package['python-software-properties'],
          }

          package { $::zfs::package_name:
            require => Apt::Ppa['ppa:zfs-native/stable'],
          }
        }
        default: {

          # Dpkg can't install from a URL like RPM can so use the defined
          # types to replicate what is contained within the release package.
          # The alternative is some curl/wget hack to download the .deb which
          # means it must always exist on the disk somewhere
          #package { $::zfs::release_package_name:
          #  ensure   => installed,
          #  provider => dpkg,
          #  source   => $::zfs::release_package_source,
          #}

          apt::source { 'zfsonlinux':
            location    => 'http://archive.zfsonlinux.org/debian',
            repos       => 'main',
            key         => '4D5843EA',
            include_src => false,
          }

          apt::pin { 'zfsonlinux':
            originator => 'archive.zfsonlinux.org',
            priority   => 1001,
          }

          ensure_packages($::zfs::package_dependencies)

          package { $::zfs::package_name:
            ensure  => $::zfs::package_ensure,
            require => [
              #Package[$::zfs::release_package_name],
              Apt::Source['zfsonlinux'],
              Apt::Pin['zfsonlinux'],
              Package[$::zfs::package_dependencies],
            ],
          }
        }
      }
    }
    default: {}
  }
}
