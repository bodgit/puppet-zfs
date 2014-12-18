#
class zfs::params {

  case $::osfamily {
    'RedHat': {
      $package_dependencies   = ['kernel-devel']
      $package_ensure         = 'installed'
      $package_name           = 'zfs'
      $release_package_name   = 'zfs-release'
      $release_package_source = $::operatingsystem ? {
        'Fedora' => "http://archive.zfsonlinux.org/fedora/zfs-release.fc${::operatingsystemmajrelease}.noarch.rpm",
        default  => "http://archive.zfsonlinux.org/epel/zfs-release.el${::operatingsystemmajrelease}.noarch.rpm",
      }
      $service_enable         = true
      $service_ensure         = 'running'
      # Fedora and RHEL/CentOS 7+ have a systemd target rather than a service
      $service_manage         = $::operatingsystem ? {
        'Fedora' => false,
        default  => $::operatingsystemmajrelease ? {
          6       => true,
          default => false,
        },
      }
      $service_name           = 'zfs'
    }
    'Debian': {
      $operatingsystem_real   = downcase($::operatingsystem)
      $package_dependencies   = []
      $package_ensure         = 'installed'
      $package_name           = "${operatingsystem_real}-zfs"
      $release_package_name   = 'zfsonlinux'
      $release_package_source = "http://archive.zfsonlinux.org/debian/pool/main/z/zfsonlinux/zfsonlinux_3~${::lsbdistcodename}_all.deb"
      $service_enable         = true
      $service_ensure         = 'running'
      $service_manage         = false
      $service_name           = 'zfs'
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.") # lint:ignore:80chars
    }
  }
}
