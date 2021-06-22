require 'spec_helper'

describe 'zfs' do

  let(:params) do
    {
      :zfs_arc_min => 0,
      :zfs_arc_max => 1,
    }
  end

  context 'on unsupported distributions' do
    let(:facts) do
      {
        :osfamily             => 'Unsupported',
        :zfs_startup_provider => 'init',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{not supported on an Unsupported}) }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :zfs_zpool_cache_present => false,
        })
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('zfs') }
      it { is_expected.to contain_class('zfs::config') }
      it { is_expected.to contain_class('zfs::install') }
      it { is_expected.to contain_class('zfs::params') }
      it { is_expected.to contain_class('zfs::service') }
      it { is_expected.to contain_file('/etc/zfs') }

      it { is_expected.to contain_kmod__option('zfs zfs_arc_min').with_value('0') }
      it { is_expected.to contain_kmod__option('zfs zfs_arc_max').with_value('1') }

      case facts[:osfamily]
      when 'Debian'
        case facts[:operatingsystem]
        when 'Debian'
          it { is_expected.to contain_package("linux-headers-#{facts[:kernelrelease]}") }
          it { is_expected.to contain_package("linux-headers-#{facts[:architecture]}") }
          it { is_expected.to contain_package('zfs-dkms') }
        end
        it { is_expected.to contain_package('zfsutils-linux') }
        it { is_expected.to contain_service('zfs-import-cache').with_ensure('stopped') }
        it { is_expected.to contain_service('zfs-import-scan').with_ensure('running') }
        it { is_expected.to contain_service('zfs-mount') }
        it { is_expected.to contain_service('zfs-share') }
      when 'RedHat'
        it { is_expected.to contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux') }
        it { is_expected.to contain_package("kernel-devel-#{facts[:kernelrelease]}") }
        it { is_expected.to contain_package('zfs') }
        it { is_expected.not_to contain_package('zfs-release') }
        it { is_expected.to contain_service('zfs-mount') }
        it { is_expected.to contain_service('zfs-share') }
        it { is_expected.to contain_yumrepo('zfs') }
        it { is_expected.to contain_yumrepo('zfs-kmod') }
        it { is_expected.to contain_yumrepo('zfs-source') }
        it { is_expected.to contain_yumrepo('zfs-testing') }
        it { is_expected.to contain_yumrepo('zfs-testing-kmod') }
        it { is_expected.to contain_yumrepo('zfs-testing-source') }

        case facts[:operatingsystemmajrelease]
        when '6'
          it { is_expected.to contain_exec('modprobe zfs') }
          it { is_expected.to contain_service('zfs-import') }
        else
          it { is_expected.to contain_exec('zfs systemctl daemon-reload') }
          it { is_expected.to contain_file('/etc/systemd/system/zfs-import-cache.service.d/override.conf') }
          it { is_expected.to contain_file('/etc/systemd/system/zfs-import-cache.service.d') }
          it { is_expected.to contain_file('/etc/systemd/system/zfs-import-scan.service.d/override.conf') }
          it { is_expected.to contain_file('/etc/systemd/system/zfs-import-scan.service.d') }
          it { is_expected.to contain_file('/etc/systemd/system/zfs-mount.service.d/override.conf') }
          it { is_expected.to contain_file('/etc/systemd/system/zfs-mount.service.d') }
          it { is_expected.to contain_service('zfs-import-cache').with_ensure('stopped') }
          it { is_expected.to contain_service('zfs-import-scan').with_ensure('running') }
        end
      end
    end
  end
end
