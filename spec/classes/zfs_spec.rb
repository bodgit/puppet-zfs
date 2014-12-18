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

    context 'version 6', :compile do
      let(:facts) do
        super().merge(
          {
            :operatingsystemmajrelease => 6
          }
        )
      end

      it do
        should contain_class('zfs')
        should contain_class('epel')
        should contain_package('zfs-release').with(
          'source' => "http://archive.zfsonlinux.org/epel/zfs-release.el6.noarch.rpm"
        )
        should contain_package('kernel-devel')
        should contain_package('zfs')
        should contain_service('zfs').with(
          'ensure' => 'running',
          'enable' => true
        )
      end
    end

    context 'version 7', :compile do
      let(:facts) do
        super().merge(
          {
            :operatingsystemmajrelease => 7
          }
        )
      end

      it do
        should contain_class('zfs')
        should contain_class('epel')
        should contain_package('zfs-release').with(
          'source' => "http://archive.zfsonlinux.org/epel/zfs-release.el7.noarch.rpm"
        )
        should contain_package('kernel-devel')
        should contain_package('zfs')
        should_not contain_service('zfs')
      end
    end
  end

  context 'on Fedora' do
    let(:facts) do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'Fedora'
      }
    end

    [18, 19, 20].each do |version|
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
          should_not contain_class('epel')
          should contain_package('zfs-release').with(
            'source' => "http://archive.zfsonlinux.org/fedora/zfs-release.fc#{version}.noarch.rpm"
          )
          should contain_package('kernel-devel')
          should contain_package('zfs')
          should_not contain_service('zfs')
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

    ['precise', 'trusty'].each do |codename|
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
          should_not contain_service('zfs')
        end
      end
    end
  end

  context 'on Debian' do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :lsbdistid       => 'Debian'
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
          should contain_class('apt')
          should contain_apt__source('zfsonlinux')
          should contain_apt__pin('zfsonlinux')
          #should contain_package('zfsonlinux').with(
          #  'source' => "http://archive.zfsonlinux.org/debian/pool/main/z/zfsonlinux/zfsonlinux_3~#{codename}_all.deb"
          #)
          should contain_package('debian-zfs')
          should_not contain_service('zfs')
        end
      end
    end
  end
end
