file { '/var/puppet':
  ensure => directory,
}

file { '/var/puppet/hello':
  ensure  => present,
  content => 'Hello Puppet and Docker',
}
