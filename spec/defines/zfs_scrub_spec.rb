require 'spec_helper'

describe 'zfs::scrub' do

  let(:title) do
    'test'
  end

  let(:params) do
    {
      :hour     => '1',
      :minute   => '0',
      :month    => '*',
      :monthday => '1',
      :weekday  => '*',
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :zfs_startup_provider    => 'init',
          :zfs_zpool_cache_present => false,
        })
      end

      context 'without zfs class included' do
        it { is_expected.to compile.and_raise_error(%r{must include the zfs base class}) }
      end

      context 'with zfs class included' do

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_cron('zpool scrub test') }
        it { is_expected.to contain_zfs__scrub('test') }

        case facts[:osfamily]
        when 'Debian'

          let(:pre_condition) do
            'include ::apt include ::zfs'
          end

        when 'RedHat'

          let(:pre_condition) do
            'include ::zfs'
          end

        end
      end
    end
  end
end
