#
class zfs::service {

  if $::zfs::service_manage {
    service { $::zfs::service_name:
      ensure     => $::zfs::service_ensure,
      enable     => $::zfs::service_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
