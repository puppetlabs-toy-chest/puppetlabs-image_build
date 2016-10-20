file { '/var/temp':
  ensure  => present,
  content => 'Hello Puppet and Docker',
}
