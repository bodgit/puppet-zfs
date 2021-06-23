require 'spec_helper'

describe 'zfs::zed::zedlet' do
  let(:title) do
    'test.sh'
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_zfs__zed__zedlet('test.sh') }

      case facts[:osfamily]
      when 'Debian'
        if (facts[:os]['name'].eql?('Debian') && facts[:os]['release']['major'].eql?('9')) || (facts[:os]['name'].eql?('Ubuntu') && facts[:os]['release']['full'].eql?('18.04'))
          it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/lib/x86_64-linux-gnu/zfs/zed.d/test.sh') }
        elsif facts[:os]['name'].eql?('Ubuntu') && facts[:os]['release']['full'].eql?('16.04')
          it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/lib/zfs-linux/zfs/zed.d/test.sh') }
        else
          it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/lib/zfs-linux/zed.d/test.sh') }
        end
      when 'RedHat'
        it { is_expected.to contain_file('/etc/zfs/zed.d/test.sh').with_target('/usr/libexec/zfs/zed.d/test.sh') }
      end
    end
  end
end
