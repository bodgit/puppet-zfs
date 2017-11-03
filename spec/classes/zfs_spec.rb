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

    it { expect { should compile }.to raise_error(/not supported on an Unsupported/) }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}", :compile do
      let(:facts) do
        facts.merge({
          :zfs_startup_provider    => case facts[:osfamily]
                                      when 'RedHat'
                                        case facts[:operatingsystemmajrelease]
                                        when '6'
                                          'init'
                                        else
                                          'systemd'
                                        end
                                      when 'Debian'
                                        case facts[:operatingsystem]
                                        when 'Ubuntu'
                                          case facts[:operatingsystemrelease]
                                          when '12.04', '14.04'
                                            'init'
                                          else
                                            'systemd'
                                          end
                                        else
                                          'systemd'
                                        end
                                      end,
          :zfs_zpool_cache_present => false,
        })
      end

      it { should contain_class('zfs') }
      it { should contain_class('zfs::config') }
      it { should contain_class('zfs::install') }
      it { should contain_class('zfs::params') }
      it { should contain_class('zfs::service') }
      it { should contain_file('/etc/zfs') }

      it { should contain_kmod__option('zfs zfs_arc_min').with_value('0') }
      it { should contain_kmod__option('zfs zfs_arc_max').with_value('1') }

      case facts[:osfamily]
      when 'Debian'

        let(:pre_condition) do
          'include ::apt'
        end

        case facts[:operatingsystem]
        when 'Ubuntu'
          case facts[:operatingsystemrelease]
          when '12.04', '14.04'
            it { should contain_apt__ppa('ppa:zfs-native/stable') }
            it { should contain_exec('modprobe zfs') }
            it { should contain_package('python-software-properties') }
            it { should contain_package('ubuntu-zfs') }
            it { should contain_service('zpool-import') }
            it { should_not contain_service('zfs-mount') }
            it { should_not contain_service('zfs-share') }
          else
            it { should contain_package('zfsutils-linux') }
            it { should contain_service('zfs-import-cache').with_ensure('stopped') }
            it { should contain_service('zfs-import-scan').with_ensure('running') }
            it { should contain_service('zfs-mount') }
            it { should contain_service('zfs-share') }
          end
        else
          it { should contain_package("linux-headers-#{facts[:kernelrelease]}") }
          it { should contain_package('zfsutils-linux') }
          it { should contain_service('zfs-import-cache').with_ensure('stopped') }
          it { should contain_service('zfs-import-scan').with_ensure('running') }
          it { should contain_service('zfs-mount') }
          it { should contain_service('zfs-share') }
        end
      when 'RedHat'
        it { should contain_augeas('/etc/yum.repos.d/zfs.repo/zfs/enabled') }
        it { should contain_augeas('/etc/yum.repos.d/zfs.repo/zfs-kmod/enabled') }
        it { should contain_package('kernel-devel') }
        it { should contain_package('zfs') }
        it { should contain_package('zfs-release') }
        it { should contain_service('zfs-mount') }
        it { should contain_service('zfs-share') }

        case facts[:operatingsystemmajrelease]
        when '6'
          it { should contain_exec('modprobe zfs') }
          it { should contain_service('zfs-import') }
        else
          it { should contain_service('zfs-import-cache').with_ensure('stopped') }
          it { should contain_service('zfs-import-scan').with_ensure('running') }
        end
      end
    end
  end
end
