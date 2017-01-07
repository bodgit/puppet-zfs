require 'spec_helper'

describe 'zfs::zed' do

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
    context "on #{os}" do
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

      context 'without zfs class included' do
        it { expect { should compile }.to raise_error(/must include the zfs base class/) }
      end

      context 'with zfs class included', :compile do

        it { should contain_class('zfs') }
        it { should contain_class('zfs::zed') }
        it { should contain_class('zfs::zed::config') }
        it { should contain_class('zfs::zed::install') }
        it { should contain_class('zfs::zed::service') }
        it { should contain_file('/etc/zfs/zed.d') }
        it { should contain_file('/etc/zfs/zed.d/zed.rc') }
        it { should contain_file('/etc/zfs/zed.d/zed-functions.sh') }
        [
          'all-syslog.sh',
          'checksum-notify.sh',
          'checksum-spare.sh',
          'data-notify.sh',
          'io-notify.sh',
          'io-spare.sh',
          'resilver.finish-notify.sh',
          'scrub.finish-notify.sh',
        ].each do |x|
          it { should contain_file("/etc/zfs/zed.d/#{x}") }
          it { should contain_zfs__zed__zedlet(x) }
        end

        case facts[:osfamily]
        when 'Debian'

          let(:pre_condition) do
            'include ::apt include ::zfs'
          end

          case facts[:operatingsystem]
          when 'Ubuntu'
            it { should contain_service('zed') }
            case facts[:operatingsystemrelease]
            when '12.04', '14.04'
            else
              it { should contain_zfs__zed__zedlet('zed-functions.sh') }
            end
          else
            it { should contain_exec('systemctl daemon-reload') }
            it { should contain_file('/etc/systemd/system/zfs-zed.service.d') }
            it { should contain_file('/etc/systemd/system/zfs-zed.service.d/override.conf') }
            it { should contain_service('zfs-zed') }
          end

          it { should contain_package('zfs-zed') }
        when 'RedHat'

          let(:pre_condition) do
            'include ::zfs'
          end

          it { should contain_service('zfs-zed') }
        end
      end
    end
  end
end
