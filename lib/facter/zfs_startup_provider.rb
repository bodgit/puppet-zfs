Facter.add('zfs_startup_provider') do
  confine :kernel => 'Linux'
  setcode do
    begin
      File.open('/proc/1/comm', &:readline).chomp
    rescue
      'init'
    end
  end
end

Facter.add('zfs_startup_provider') do
  setcode do
    'init'
  end
end
