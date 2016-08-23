define webserver {
  Service {
    provider => dummy
  }

  class { 'nginx': }

  file { '/var/www/html/index.html':
    ensure  => present,
    content => $title,
    require => Class['nginx::package'],
  }

  exec { 'Disable Nginx daemon mode':
    path    => '/bin',
    command => 'echo "daemon off;" >> /etc/nginx/nginx.conf',
    unless  => 'grep "daemon off" /etc/nginx/nginx.conf',
    require => Class['nginx::package'],
  }
}


node /^node1/ {
  webserver { 'hello node 1': }
}

node /^node2/ {
  webserver { 'hello node 2': }
}
