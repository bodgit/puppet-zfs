require 'spec_helper'

describe 'zfs::scrub' do
  let(:title) do
    'test'
  end

  let(:params) do
    {
      hour:     '1',
      minute:   '0',
      month:    '*',
      monthday: '1',
      weekday:  '*',
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_cron('zpool scrub test') }
      it { is_expected.to contain_zfs__scrub('test') }
    end
  end
end
