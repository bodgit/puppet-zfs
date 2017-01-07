require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    hosts.each do |host|
      puppet_module_install(:source => proj_root, :module_name => 'zfs')
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-apt'),    { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','camptocamp-kmod'),   { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','stahnma-epel'),      { :acceptable_exit_codes => [0,1] }
    end
  end
end
