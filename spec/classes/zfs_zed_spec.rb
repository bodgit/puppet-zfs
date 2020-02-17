require 'spec_helper'

describe 'zfs::zed' do

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

      context 'without zfs class included' do
        it { is_expected.to compile.and_raise_error(%r{must include the zfs base class}) }
      end

      context 'with zfs class included' do

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('zfs') }
        it { is_expected.to contain_class('zfs::zed') }
        it { is_expected.to contain_class('zfs::zed::config') }
        it { is_expected.to contain_class('zfs::zed::install') }
        it { is_expected.to contain_class('zfs::zed::service') }
        it { is_expected.to contain_file('/etc/zfs/zed.d') }
        it { is_expected.to contain_file('/etc/zfs/zed.d/zed.rc') }
        it { is_expected.to contain_file('/etc/zfs/zed.d/zed-functions.sh') }

        case facts[:osfamily]
        when 'Debian'

          let(:pre_condition) do
            'include ::apt include ::zfs'
          end

          case facts[:operatingsystem]
          when 'Ubuntu'
            it { is_expected.to contain_service('zed') }
            case facts[:operatingsystemrelease]
            when '12.04', '14.04'
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
                it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
                it { is_expected.to contain_zfs__zed__zedlet(x) }
              end
            when '16.04'
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
                it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
                it { is_expected.to contain_zfs__zed__zedlet(x) }
              end
              it { is_expected.to contain_zfs__zed__zedlet('zed-functions.sh') }
            else
              [
                'all-syslog.sh',
                'data-notify.sh',
                'pool_import-led.sh',
                'resilver_finish-notify.sh',
                'scrub_finish-notify.sh',
                'statechange-led.sh',
                'statechange-notify.sh',
                'vdev_attach-led.sh',
                'vdev_clear-led.sh',
              ].each do |x|
                it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
                it { is_expected.to contain_zfs__zed__zedlet(x) }
              end
            end
          else
            it { is_expected.to contain_exec('systemctl daemon-reload') }
            it { is_expected.to contain_file('/etc/systemd/system/zfs-zed.service.d') }
            it { is_expected.to contain_file('/etc/systemd/system/zfs-zed.service.d/override.conf') }
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
              it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
              it { is_expected.to contain_zfs__zed__zedlet(x) }
            end
            it { is_expected.to contain_service('zfs-zed') }
          end

          it { is_expected.to contain_package('zfs-zed') }
        when 'RedHat'

          let(:pre_condition) do
            'include ::zfs'
          end

          case facts[:operatingsystemmajrelease]
          when '6'
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
              it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
              it { is_expected.to contain_zfs__zed__zedlet(x) }
            end
          else
            [
              'all-syslog.sh',
              'data-notify.sh',
              'pool_import-led.sh',
              'resilver_finish-notify.sh',
              'resilver_finish-start-scrub.sh',
              'scrub_finish-notify.sh',
              'statechange-led.sh',
              'statechange-notify.sh',
              'vdev_attach-led.sh',
              'vdev_clear-led.sh',
            ].each do |x|
              it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
              it { is_expected.to contain_zfs__zed__zedlet(x) }
            end
          end

          it { is_expected.to contain_service('zfs-zed') }
        end
      end
    end
  end
end
