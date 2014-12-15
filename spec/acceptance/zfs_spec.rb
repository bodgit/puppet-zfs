require 'spec_helper_acceptance'

describe 'zfs' do
  context 'running puppet code' do
    pp = <<-EOS
      include ::zfs
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end
end
