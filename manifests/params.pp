# @!visibility private
class zfs::params {

  $conf_dir         = '/etc/zfs'
  $kmod_type        = 'dkms'
  $service_manage   = true
  $zed_conf_dir     = "${conf_dir}/zed.d"
  $zedlets          = {
    'all-syslog.sh'             => {},
    'checksum-notify.sh'        => {},
    'checksum-spare.sh'         => {},
    'data-notify.sh'            => {},
    'io-notify.sh'              => {},
    'io-spare.sh'               => {},
    'resilver.finish-notify.sh' => {},
    'scrub.finish-notify.sh'    => {},
  }

  case $::osfamily {
    'RedHat': {
      $manage_repo      = true
      $zed_package_name = undef
      $zed_service_name = 'zfs-zed'
      $zedlet_dir       = '/usr/libexec/zfs/zed.d'
      $zfs_package_name = 'zfs'
    }
    'Debian': {
      $zed_package_name = 'zfs-zed'

      case $::operatingsystem {
        'Ubuntu': {
          $zed_service_name = 'zed'
          $zedlet_dir       = '/usr/lib/zfs-linux/zfs/zed.d'

          case $::operatingsystemrelease {
            '12.04', '14.04': {
              $manage_repo      = true
              $zfs_package_name = 'ubuntu-zfs'
            }
            default: {
              $manage_repo      = false
              $zfs_package_name = 'zfsutils-linux'
            }
          }
        }
        default: {
          $manage_repo      = true
          $zed_service_name = 'zfs-zed'
          $zedlet_dir       = '/usr/lib/x86_64-linux-gnu/zfs/zed.d'
          $zfs_package_name = 'zfsutils-linux'
        }
      }
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
}
