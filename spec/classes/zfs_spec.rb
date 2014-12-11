require 'spec_helper'

describe 'zfs' do

  context 'on unsupported distributions' do
    let(:facts) do
      {
        :osfamily => 'Unsupported'
      }
    end

    it do
      expect { subject }.to raise_error(/not supported on an Unsupported/)
    end
  end

  context 'on RedHat' do
    let(:facts) do
      {
        :osfamily => 'RedHat'
      }
    end

    [6, 7].each do |version|
      context "version #{version}", :compile do
        let(:facts) do
          super().merge(
            {
              :operatingsystemmajrelease => version
            }
          )
        end

        it do
          should contain_class('zfs')
          should contain_class('epel')
          should contain_package('zfs-release').with(
            'source' => "http://archive.zfsonlinux.org/epel/zfs-release.el#{version}.noarch.rpm"
          )
          should contain_package('kernel-devel')
          should contain_package('zfs')
          should contain_service('zfs').with(
            'ensure' => 'running',
            'enable' => true
          )
        end
      end
    end
  end

  context 'on Ubuntu' do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
        :lsbdistid       => 'Ubuntu'
      }
    end

    ['lucid', 'precise', 'trusty'].each do |codename|
      context "#{codename}", :compile do
        let(:facts) do
          super().merge(
            {
              :lsbdistcodename => codename
            }
          )
        end

        it do
          should contain_class('zfs')
          should contain_class('apt')
          should contain_apt__ppa('ppa:zfs-native/stable')
          should contain_package('python-software-properties')
          should contain_package('ubuntu-zfs')
          should contain_service('zfs').with(
            'ensure' => 'running',
            'enable' => true
          )
        end
      end
    end
  end

  context 'on Debian' do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian'
      }
    end

    ['squeeze', 'wheezy'].each do |codename|
      context "#{codename}", :compile do
        let(:facts) do
          super().merge(
            {
              :lsbdistcodename => codename
            }
          )
        end

        it do
          should contain_class('zfs')
          should contain_package('zfsonlinux').with(
            'source' => "http://archive.zfsonlinux.org/debian/pool/main/z/zfsonlinux/zfsonlinux_3~#{codename}_all.deb"
          )
          should contain_package('debian-zfs')
          should contain_service('zfs').with(
            'ensure' => 'running',
            'enable' => true
          )
        end
      end
    end
  end
end
