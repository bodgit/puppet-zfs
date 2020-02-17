require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

hosts.each do |host|
  # Just assume the OpenBSD box has Puppet installed already
  if host['platform'] !~ /^openbsd-/i
    run_puppet_install_helper_on(host)
  end
  on(host, '/usr/bin/test -f /etc/puppetlabs/puppet/hiera.yaml && /bin/rm -f /etc/puppetlabs/puppet/hiera.yaml || echo true')
end

install_module_on(hosts)
install_module_dependencies_on(hosts)
install_module_from_forge_on(hosts, 'stahnma/epel', '>=2.0.0 <3.0.0')

RSpec.configure do |c|
  c.formatter = :documentation
end
