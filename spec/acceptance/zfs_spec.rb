require 'spec_helper_acceptance'

describe 'zfs' do
  case fact('osfamily')
  when 'RedHat'
    case fact('operatingsystemmajrelease')
    when '6'
      zpool = '/sbin/zpool'
      zfs   = '/sbin/zfs'
    else
      zpool = '/usr/sbin/zpool'
      zfs   = '/usr/sbin/zfs'
    end
  else
    zpool = '/sbin/zpool'
    zfs   = '/sbin/zfs'
  end

  it 'should work with no errors' do
    pp = <<-EOS
      include ::zfs
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  [zpool, zfs].each do |exe|
    describe file(exe) do
      it { should be_executable }
    end
  end

  (1..3).each do |file|
    # The Debian images have an ext3 filesystem so fallocate(1) doesn't work
    describe command("fallocate -l 1G /tmp/file#{file}"), :if => fact('operatingsystem') != 'Debian' do
      its(:exit_status) { should eq 0 }
    end
    describe command("dd if=/dev/zero of=/tmp/file#{file} count=1 bs=1G"), :if => fact('operatingsystem') == 'Debian' do
      its(:exit_status) { should eq 0 }
    end
  end

  describe command("#{zpool} create test raidz1 /tmp/file1 /tmp/file2 /tmp/file3") do
    its(:exit_status) { should eq 0 }
  end

  describe kernel_module('zfs') do
    it { should be_loaded }
  end

  describe file('/test') do
    it { should be_directory }
    it { should be_mounted.with(:device => 'test', :type => 'zfs') }
  end

  describe command("#{zfs} create test/test") do
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

  describe command("#{zpool} destroy test") do
    its(:exit_status) { should eq 0 }
  end

  describe file('/test') do
    it { should_not be_directory }
  end
end
