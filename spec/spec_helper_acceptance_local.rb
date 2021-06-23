# frozen_string_literal: true

require 'singleton'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

def zfs_settings_hash
  zfs = {}

  case host_inventory['facter']['os']['family']
  when 'Debian'
    zfs['logfile']      = '/var/log/syslog'
    zfs['package']      = 'zfsutils-linux'
    zfs['have_systemd'] = true
    zfs['zed_service']  = host_inventory['facter']['os']['release']['full'].eql?('16.04') ? 'zed' : 'zfs-zed'
  when 'RedHat'
    zfs['logfile']      = '/var/log/messages'
    zfs['package']      = 'zfs'
    zfs['have_systemd'] = host_inventory['facter']['os']['release']['major'].eql?('6') ? false : true
    zfs['zed_service']  = 'zfs-zed'
  else
    raise 'unknown operating system'
  end

  zfs
end

RSpec.configure do |c|
  c.before :suite do
    LitmusHelper.instance.run_shell('puppet module install puppet/epel')
    LitmusHelper.instance.run_shell('puppet module install puppetlabs/apt')
  end
end
