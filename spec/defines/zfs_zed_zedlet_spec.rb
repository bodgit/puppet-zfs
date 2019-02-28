require 'spec_helper'

describe 'zfs::zed::zedlet' do

  let(:title) do
    'test.sh'
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :zfs_startup_provider    => 'init',
          :zfs_zpool_cache_present => false,
        })
      end

      context 'without zfs::zed class included' do
        it { is_expected.to compile.and_raise_error(%r{must include the zfs::zed base class}) }
      end

      context 'with zfs::zed class included' do

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_zfs__zed__zedlet('test.sh') }

        case facts[:osfamily]
        when 'Debian'

          let(:pre_condition) do
            'include ::apt include ::zfs include ::zfs::zed'
          end

          case facts[:operatingsystem]
          when 'Ubuntu'
            it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/lib/zfs-linux/zfs/zed.d/test.sh') }
          else
            it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/lib/x86_64-linux-gnu/zfs/zed.d/test.sh') }
          end

        when 'RedHat'

          let(:pre_condition) do
            'include ::zfs include ::zfs::zed'
          end

          it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/libexec/zfs/zed.d/test.sh') }

        end
      end
    end
  end
end
