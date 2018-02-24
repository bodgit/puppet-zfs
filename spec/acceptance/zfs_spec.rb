require 'spec_helper_acceptance'

describe 'zfs' do
  case fact('osfamily')
  when 'Debian'
    logfile = '/var/log/syslog'
    zpool   = '/sbin/zpool'
    zfs     = '/sbin/zfs'
    case fact('operatingsystem')
    when 'Ubuntu'
      zed_service = 'zed'
      case fact('operatingsystemrelease')
      when '12.04', '14.04'
        package = 'ubuntu-zfs'
        systemd = false
      else
        package = 'zfsutils-linux'
        systemd = true
      end
    else
      package     = 'zfsutils-linux'
      systemd     = true
      zed_service = 'zfs-zed'
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

  it 'should work with no errors' do
    pp = <<-EOS
      case $::osfamily {
        'Debian': {
          include ::apt

          ::apt::setting { 'conf-recommends':
            content => @(EOS/L),
              APT::Install-Recommends "false";
              APT::Install-Suggests "false";
              | EOS
          }

          case $::operatingsystem {
            'Debian': {
              case $::operatingsystemmajrelease {
                '8': {
                  class { '::apt::backports':
                    pin    => 500,
                    before => Class['::zfs'],
                  }
                }
                default: {
                  ::apt::source { 'contrib':
                    location => 'http://deb.debian.org/debian',
                    repos    => 'contrib',
                    before   => Class['::zfs'],
                  }
                }
              }
            }
            default: {
              Class['::apt'] -> Class['::zfs']
            }
          }
        }
        'RedHat': {
          include ::epel

          Class['::epel'] -> Class['::zfs']
        }
      }

      class { '::zfs':
        zfs_arc_min => 134217728,
        zfs_arc_max => 268435456,
      }

      class { '::zfs::zed':
        #email_addrs    => ['root'],
        #email_prog     => 'mail',
        #email_opts     => '',
        notify_verbose => true,
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  describe package('zfs-release'), :if => fact('osfamily').eql?('RedHat') do
    it { should be_installed }
  end

  describe package(package) do
    it { should be_installed }
  end

  describe kernel_module('zfs') do
    it { should be_loaded }
  end

  describe file('/proc/spl/kstat/zfs/arcstats') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match /^c_min \s+ 4 \s+ 134217728$/x }
    its(:content) { should match /^c_max \s+ 4 \s+ 268435456$/x }
  end

  describe file('/etc/zfs') do
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 755 }
  end

  describe file('/etc/zfs/zpool.cache') do
    it { should_not exist }
  end

  [zpool, zfs].each do |exe|
    describe file(exe) do
      it { should be_file }
      it { should be_executable }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      it { should be_mode 755 }
    end
  end

  describe service('zfs-import'), :if => systemd.eql?(false) and fact('osfamily').eql?('RedHat') do
    it { should be_running }
    it { should be_enabled }
  end

  describe service('zpool-import'), :if => systemd.eql?(false) and fact('operatingsystem').eql?('Ubuntu') do
    it { should be_stopped }
    it { should be_enabled }
  end

  describe service('zfs-import-cache'), :if => systemd.eql?(true) do
    it { should_not be_running }
    it { should be_enabled }
  end

  describe service('zfs-import-scan'), :if => systemd.eql?(true) do
    it { should be_running }
    it { should be_enabled }
  end

  describe service('zfs-mount'), :unless => fact('operatingsystem').eql?('Ubuntu') and ['12.04', '14.04'].include?(fact('operatingsystemrelease')) do
    it { should be_running }
    it { should be_enabled }
  end

  describe service('zfs-share'), :unless => fact('operatingsystem').eql?('Ubuntu') and ['12.04', '14.04'].include?(fact('operatingsystemrelease')) do
    it { should be_running }
    it { should be_enabled }
  end

  describe file('/etc/zfs/zed.d') do
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 755 }
  end

  describe file('/etc/zfs/zed.d/zed.rc') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 600 }
    its(:content) { should match /^ZED_NOTIFY_VERBOSE=1$/ }
  end

  describe service(zed_service) do
    it { should be_running }
    it { should be_enabled }
  end

  (1..3).each do |file|
    # The Debian 8 image has an ext3 filesystem so fallocate(1) doesn't work
    describe command("fallocate -l 1G /tmp/file#{file}"), :unless => (fact('operatingsystem').eql?('Debian') and fact('operatingsystemmajrelease').eql?('8')) do
      its(:exit_status) { should eq 0 }
    end
    describe command("dd if=/dev/zero of=/tmp/file#{file} count=1 bs=1G"), :if => (fact('operatingsystem').eql?('Debian') and fact('operatingsystemmajrelease').eql?('8')) do
      its(:exit_status) { should eq 0 }
    end
  end

  describe command('zpool create test raidz1 /tmp/file1 /tmp/file2 /tmp/file3') do
    its(:exit_status) { should eq 0 }
  end

  describe file('/etc/zfs/zpool.cache') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 644 }
  end

  describe file('/test') do
    it { should be_directory }
    it { should be_mounted.with(:device => 'test', :type => 'zfs') }
  end

  describe command('zfs create test/test') do
    its(:exit_status) { should eq 0 }
  end

  describe file('/test/test') do
    it { should be_directory }
    it { should be_mounted.with(:device => 'test/test', :type => 'zfs') }
  end

  describe command('touch /test/test/test') do
    its(:exit_status) { should eq 0 }
  end

  describe file('/test/test/test') do
    it { should be_file }
  end

  # Issue a scrub and give it enough time to finish
  describe command('zpool scrub test && sleep 5s') do
    its(:exit_status) { should eq 0 }
  end

  # Check zed noticed and sent the scrub events to syslog
  describe file(logfile) do
    it { should be_file }
    its(:content) { should match /zed (?:\[\d+\])? : \s eid=\d+ \s class=scrub.start \s pool=test$/x }
    its(:content) { should match /zed (?:\[\d+\])? : \s eid=\d+ \s class=scrub.finish \s pool=test$/x }
  end

  describe command('zpool destroy test') do
    its(:exit_status) { should eq 0 }
  end

  describe file('/test') do
    it { should_not be_directory }
  end
end
