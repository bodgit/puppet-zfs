require 'spec_helper'

describe 'zfs::zed' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('zfs') }
      it { is_expected.to contain_class('zfs::zed') }
      it { is_expected.to contain_class('zfs::zed::config') }
      it { is_expected.to contain_class('zfs::zed::install') }
      it { is_expected.to contain_class('zfs::zed::service') }
      it { is_expected.to contain_file('/etc/zfs/zed.d') }
      it { is_expected.to contain_file('/etc/zfs/zed.d/zed.rc') }
      it { is_expected.to contain_file('/etc/zfs/zed.d/zed-functions.sh') }

      if facts[:os]['name'].eql?('Debian')
        it { is_expected.to contain_exec('systemctl daemon-reload') }
        it { is_expected.to contain_file('/etc/systemd/system/zfs-zed.service.d') }
        it { is_expected.to contain_file('/etc/systemd/system/zfs-zed.service.d/override.conf') }
      end

      if facts[:os]['family'].eql?('Debian')
        it { is_expected.to contain_package('zfs-zed') }
      end

      if facts[:os]['name'].eql?('Ubuntu') && facts[:os]['release']['full'].eql?('16.04')
        it { is_expected.to contain_service('zed') }
        it { is_expected.to contain_zfs__zed__zedlet('zed-functions.sh') }
      else
        it { is_expected.to contain_service('zfs-zed') }
      end

      zedlets = case facts[:os]['family']
                when 'RedHat'
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
                  ]
                when 'Debian'
                  case facts[:os]['name']
                  when 'Ubuntu'
                    case facts[:os]['release']['full']
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
                      ]
                    when '18.04'
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
                      ]
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
                      ]
                    end
                  else
                    case facts[:os]['release']['major']
                    when '9'
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
                      ]
                    else
                      [
                        'all-syslog.sh',
                        'data-notify.sh',
                        'history_event-zfs-list-cacher.sh',
                        'pool_import-led.sh',
                        'resilver_finish-notify.sh',
                        'resilver_finish-start-scrub.sh',
                        'scrub_finish-notify.sh',
                        'statechange-led.sh',
                        'statechange-notify.sh',
                        'vdev_attach-led.sh',
                        'vdev_clear-led.sh',
                      ]
                    end
                  end
                else
                  []
                end

      zedlets.each do |x|
        it { is_expected.to contain_file("/etc/zfs/zed.d/#{x}") }
        it { is_expected.to contain_zfs__zed__zedlet(x) }
      end
    end
  end
end
