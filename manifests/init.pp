#
class zfs (
  $package_dependencies   = $::zfs::params::package_dependencies,
  $package_ensure         = $::zfs::params::package_ensure,
  $package_name           = $::zfs::params::package_name,
  $release_package_name   = $::zfs::params::release_package_name,
  $release_package_source = $::zfs::params::release_package_source,
  $service_enable         = $::zfs::params::service_enable,
  $service_ensure         = $::zfs::params::service_ensure,
  $service_manage         = $::zfs::params::service_manage,
  $service_name           = $::zfs::params::service_name
) inherits ::zfs::params {

  validate_array($package_dependencies)
  validate_re($package_ensure, '^(installed|absent)$')
  validate_string($package_name)
  validate_string($release_package_name)
  validate_string($release_package_source)
  validate_bool($service_enable)
  validate_re($service_ensure, '^(running|stopped)$')
  validate_bool($service_manage)
  validate_string($service_name)

  include ::zfs::install
  include ::zfs::service

  anchor { 'zfs::begin': }
  anchor { 'zfs::end': }

  Anchor['zfs::begin'] -> Class['::zfs::install'] ~> Class['::zfs::service']
    -> Anchor['zfs::end']
}
