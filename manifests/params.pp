# @!visibility private
class zfs::params {

  $conf_dir       = '/etc/zfs'
  $kmod_type      = 'dkms'
  $service_manage = true
  $zed_conf_dir   = "${conf_dir}/zed.d"

  case $facts['os']['family'] {
    'RedHat': {
      $manage_repo      = true
      $zed_package_name = undef
      $zed_service_name = 'zfs-zed'
      $zedlet_dir       = '/usr/libexec/zfs/zed.d'
      $zedlets          = {
        'all-syslog.sh'                  => {},
        'data-notify.sh'                 => {},
        'pool_import-led.sh'             => {},
        'resilver_finish-notify.sh'      => {},
        'resilver_finish-start-scrub.sh' => {},
        'scrub_finish-notify.sh'         => {},
        'statechange-led.sh'             => {},
        'statechange-notify.sh'          => {},
        'vdev_attach-led.sh'             => {},
        'vdev_clear-led.sh'              => {},
      }
      $zfs_package_name = 'zfs'
    }
    'Debian': {
      $manage_repo      = false
      $zed_package_name = 'zfs-zed'

      case $facts['os']['name'] {
        'Ubuntu': {
          $zfs_package_name = 'zfsutils-linux'

          case $facts['os']['release']['full'] {
            '16.04': {
              $zed_service_name = 'zed'
              $zedlet_dir       = '/usr/lib/zfs-linux/zfs/zed.d'
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
            }
            '18.04': {
              $zed_service_name = 'zfs-zed'
              $zedlet_dir       = '/usr/lib/x86_64-linux-gnu/zfs/zed.d'
              $zedlets          = {
                'all-syslog.sh'             => {},
                'data-notify.sh'            => {},
                'pool_import-led.sh'        => {},
                'resilver_finish-notify.sh' => {},
                'scrub_finish-notify.sh'    => {},
                'statechange-led.sh'        => {},
                'statechange-notify.sh'     => {},
                'vdev_attach-led.sh'        => {},
                'vdev_clear-led.sh'         => {},
              }
            }
            default: {
              $zed_service_name = 'zfs-zed'
              $zedlet_dir       = '/usr/lib/zfs-linux/zed.d'
              $zedlets          = {
                'all-syslog.sh'                  => {},
                'data-notify.sh'                 => {},
                'pool_import-led.sh'             => {},
                'resilver_finish-notify.sh'      => {},
                'resilver_finish-start-scrub.sh' => {},
                'scrub_finish-notify.sh'         => {},
                'statechange-led.sh'             => {},
                'statechange-notify.sh'          => {},
                'vdev_attach-led.sh'             => {},
                'vdev_clear-led.sh'              => {},
              }
            }
          }
        }
        default: {
          $zed_service_name = 'zfs-zed'
          $zfs_package_name = [
            'zfs-dkms',
            'zfsutils-linux',
          ]

          case $facts['os']['release']['major'] {
            '9': {
              $zedlet_dir = '/usr/lib/x86_64-linux-gnu/zfs/zed.d'
              $zedlets    = {
                'all-syslog.sh'                  => {},
                'data-notify.sh'                 => {},
                'pool_import-led.sh'             => {},
                'resilver_finish-notify.sh'      => {},
                'resilver_finish-start-scrub.sh' => {},
                'scrub_finish-notify.sh'         => {},
                'statechange-led.sh'             => {},
                'statechange-notify.sh'          => {},
                'vdev_attach-led.sh'             => {},
                'vdev_clear-led.sh'              => {},
              }
            }
            default: {
              $zedlet_dir = '/usr/lib/zfs-linux/zed.d'
              $zedlets    = {
                'all-syslog.sh'                    => {},
                'data-notify.sh'                   => {},
                'history_event-zfs-list-cacher.sh' => {},
                'pool_import-led.sh'               => {},
                'resilver_finish-notify.sh'        => {},
                'resilver_finish-start-scrub.sh'   => {},
                'scrub_finish-notify.sh'           => {},
                'statechange-led.sh'               => {},
                'statechange-notify.sh'            => {},
                'vdev_attach-led.sh'               => {},
                'vdev_clear-led.sh'                => {},
              }
            }
          }
        }
      }
    }
    default: {
      fail("The ${module_name} module is not supported on an ${facts['os']['family']} based system.")
    }
  }
}
