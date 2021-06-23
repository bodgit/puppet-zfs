require 'spec_helper_acceptance'

zfs_hash = zfs_settings_hash

describe 'zfs' do
  let(:pp) do
    <<-MANIFEST
      case $facts['os']['family'] {
        'Debian': {
          include apt

          Class['apt'] -> Class['zfs']

          apt::setting { 'conf-recommends':
            content => @(EOS/L),
              APT::Install-Recommends "false";
              APT::Install-Suggests "false";
              | EOS
          }

          if $facts['os']['name'] == 'Debian' {
            class { 'apt::backports':
              repos  => 'main contrib',
              pin    => 990,
              before => Class['zfs'],
            }
          }
        }
        'RedHat': {
          include epel

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
    MANIFEST
  end

  it 'applies idempotently' do
    idempotent_apply(pp)
  end

  describe package('zfs-release') do
    it { is_expected.not_to be_installed }
  end

  describe package(zfs_hash['package']) do
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

  ['/sbin/zpool', '/sbin/zfs'].each do |exe|
    describe file(exe) do
      it { is_expected.to be_file }
      it { is_expected.to be_executable }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      it { is_expected.to be_mode 755 }
    end
  end

  describe service('zfs-import'), if: zfs_hash['have_systemd'].eql?(false) do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end

  describe service('zfs-import-cache'), if: zfs_hash['have_systemd'].eql?(true) do
    it { is_expected.not_to be_running }
    it { is_expected.to be_enabled }
  end

  describe service('zfs-import-scan'), if: zfs_hash['have_systemd'].eql?(true) do
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

  describe service(zfs_hash['zed_service']) do
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
  describe command('zpool scrub test && sleep 10s') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  # Check zed noticed and sent the scrub events to syslog
  describe file(zfs_hash['logfile']) do
    it { is_expected.to be_file }
    its(:content) do
      is_expected.not_to match(%r{zed (?: \[\d+\] )? : \s Failed \s to \s stat \s}x)
      is_expected.to match(%r{zed (?: \[\d+\] )? : \s eid=\d+ \s class=scrub.start \s (?: pool='?test'? | pool_guid=0x[0-9A-F]+ )}x)
      is_expected.to match(%r{zed (?: \[\d+\] )? : \s eid=\d+ \s class=scrub.finish \s (?: pool='?test'? | pool_guid=0x[0-9A-F]+ )}x)
    end
  end

  describe command('zpool destroy test') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe file('/test') do
    it { is_expected.not_to be_directory }
  end
end
