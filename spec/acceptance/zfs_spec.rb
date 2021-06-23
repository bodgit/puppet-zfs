require 'spec_helper_acceptance'

describe 'zfs' do
  case fact('osfamily')
  when 'Debian'
    logfile = '/var/log/syslog'
    package = 'zfsutils-linux'
    systemd = true
    zpool   = '/sbin/zpool'
    zfs     = '/sbin/zfs'
    zed_service = case fact('operatingsystem')
                  when 'Ubuntu'
                    'zed'
                  else
                    'zfs-zed'
                  end
  when 'RedHat'
    logfile     = '/var/log/messages'
    package     = 'zfs'
    zed_service = 'zfs-zed'
    case fact('operatingsystemmajrelease')
    when '6'
      systemd = false
      zpool   = '/sbin/zpool'
      zfs     = '/sbin/zfs'
    else
      systemd = true
      zpool   = '/usr/sbin/zpool'
      zfs     = '/usr/sbin/zfs'
    end
  end

  it 'works with no errors' do
    pp = <<-EOS
      case $::osfamily {
        'Debian': {
          include apt

          apt::setting { 'conf-recommends':
            content => @(EOS/L),
              APT::Install-Recommends "false";
              APT::Install-Suggests "false";
              | EOS
          }

          apt::setting { 'conf-validity':
            content => @(EOS/L),
              Acquire::Check-Valid-Until "false";
              | EOS
          }

          case $facts['os']['name'] {
            'Debian': {
              $snapshot = $facts['kernelrelease'] ? {
                /^4\.9\.0-9-/  => '20190601T035633Z',
                /^4\.19\.0-5-/ => '20190701T031013Z',
                default        => undef,
              }

              if $snapshot {
                apt::source { 'snapshot':
                  location => "https://snapshot.debian.org/archive/debian/${snapshot}",
                  repos    => 'main',
                  before   => Class['zfs'],
                }

                apt::source { 'updates':
                  location => "https://snapshot.debian.org/archive/debian/${snapshot}",
                  release  => "${::lsbdistcodename}-updates",
                  repos    => 'main',
                  before   => Class['zfs'],
                }

                apt::source { 'security':
                  location => "https://snapshot.debian.org/archive/debian-security/${snapshot}",
                  release  => "${::lsbdistcodename}/updates",
                  repos    => 'main',
                  before   => Class['zfs'],
                }
              }

              apt::source { 'contrib':
                location => 'http://deb.debian.org/debian',
                repos    => 'contrib',
                before   => Class['zfs'],
              }
            }
            default: {
              Class['apt'] -> Class['zfs']
            }
          }
        }
        'RedHat': {
          include epel

          case $facts['os']['name'] {
            'CentOS': {
              case $facts['os']['release']['major'] {
                '7': {
                  yumrepo { 'C7.6.1810-base':
                    baseurl  => 'http://vault.centos.org/7.6.1810/os/$basearch/',
                    descr    => 'CentOS-7.6.1810 - Base',
                    enabled  => 1,
                    gpgcheck => 1,
                    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7',
                    before   => Class['zfs'],
                  }

                  yumrepo { 'C7.6.1810-updates':
                    baseurl  => 'http://vault.centos.org/7.6.1810/updates/$basearch/',
                    descr    => 'CentOS-7.6.1810 - Updates',
                    enabled  => 1,
                    gpgcheck => 1,
                    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7',
                    before   => Class['zfs'],
                  }
                }
                '8': {
                  yumrepo { 'C8.0.1905-BaseOS':
                    ensure   => present,
                    baseurl  => 'http://mirror.centos.org/centos/8.0.1905/BaseOS/x86_64/os/',
                    descr    => 'CentOS-8.0.1905 - BaseOS',
                    enabled  => 1,
                    gpgcheck => 1,
                    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial',
                    before   => Class['zfs'],
                  }
                }
              }
            }
          }

          Class['epel'] -> Class['zfs']
        }
      }

      class { 'zfs':
        zfs_arc_min => 134217728,
        zfs_arc_max => 268435456,
      }

      class { 'zfs::zed':
        #email_addrs    => ['root'],
        #email_prog     => 'mail',
        #email_opts     => '',
        notify_verbose => true,
      }
    EOS

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end

  describe package('zfs-release'), if: fact('osfamily').eql?('RedHat') do
    it { is_expected.not_to be_installed }
  end

  describe package(package) do
    it { is_expected.to be_installed }
  end

  describe kernel_module('zfs') do
    it { is_expected.to be_loaded }
  end

  describe file('/proc/spl/kstat/zfs/arcstats') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    its(:content) do
      is_expected.to match(%r{^c_min \s+ 4 \s+ 134217728$}x)
      is_expected.to match(%r{^c_max \s+ 4 \s+ 268435456$}x)
    end
  end

  describe file('/etc/zfs') do
    it { is_expected.to be_directory }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode 755 }
  end

  describe file('/etc/zfs/zpool.cache') do
    it { is_expected.not_to exist }
  end

  [zpool, zfs].each do |exe|
    describe file(exe) do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      it { is_expected.to be_mode 755 }
    end
  end

  describe service('zfs-import'), if: systemd.eql?(false) do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe service('zfs-import-cache'), if: systemd.eql?(true) do
    it { is_expected.not_to be_running }
    it { is_expected.to be_enabled }
  end

  describe service('zfs-import-scan'), if: systemd.eql?(true) do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe file('/etc/zfs/zed.d') do
    it { is_expected.to be_directory }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode 755 }
  end

  describe file('/etc/zfs/zed.d/zed.rc') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode 600 }
    its(:content) { is_expected.to match(%r{^ZED_NOTIFY_VERBOSE=1$}) }
  end

  describe service(zed_service) do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  (1..3).each do |file|
    describe command("fallocate -l 1G /tmp/file#{file}") do
      its(:exit_status) { is_expected.to eq 0 }
    end
  end

  describe command('zpool create test raidz1 /tmp/file1 /tmp/file2 /tmp/file3') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe file('/etc/zfs/zpool.cache') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode 644 }
  end

  describe file('/test') do
    it { is_expected.to be_directory }
    it { is_expected.to be_mounted.with(device: 'test', type: 'zfs') }
  end

  describe command('zfs create test/test') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe file('/test/test') do
    it { is_expected.to be_directory }
    it { is_expected.to be_mounted.with(device: 'test/test', type: 'zfs') }
  end

  describe command('touch /test/test/test') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe file('/test/test/test') do
    it { is_expected.to be_file }
  end

  # Issue a scrub and give it enough time to finish
  describe command('zpool scrub test && sleep 5s') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  # Check zed noticed and sent the scrub events to syslog
  describe file(logfile) do
    it { is_expected.to be_file }
    its(:content) do
      is_expected.not_to match(%r{zed (?: \[\d+\] )? : \s Failed \s to \s stat \s}x)
      is_expected.to match(%r{zed (?: \[\d+\] )? : \s eid=\d+ \s class=scrub.start \s (?: pool=test | pool_guid=0x[0-9A-F]+ )}x)
      is_expected.to match(%r{zed (?: \[\d+\] )? : \s eid=\d+ \s class=scrub.finish \s (?: pool=test | pool_guid=0x[0-9A-F]+ )}x)
    end
  end

  describe command('zpool destroy test') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe file('/test') do
    it { is_expected.not_to be_directory }
  end
end
