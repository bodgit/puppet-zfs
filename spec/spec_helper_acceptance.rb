require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

hosts.each do |host|
  # Just assume the OpenBSD box has Puppet installed already
  unless %r{^openbsd-}i.match?(host['platform'])
    run_puppet_install_helper_on(host)
  end
  on(host, '/usr/bin/test -f /etc/puppetlabs/puppet/hiera.yaml && /bin/rm -f /etc/puppetlabs/puppet/hiera.yaml || echo true')
end

install_module_on(hosts)
install_module_dependencies_on(hosts)

require 'spec_helper_acceptance_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_acceptance_local.rb'))
