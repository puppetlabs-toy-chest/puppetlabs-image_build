define webserver {
  Service {
    provider => dummy
  }

  class { 'nginx': }

  nginx::resource::vhost { 'default':
    www_root => '/var/www/html',
  }

  file { '/var/www/html/index.html':
    ensure  => present,
    content => $title,
  }

  exec { 'Disable Nginx daemon mode':
    path    => '/bin',
    command => 'echo "daemon off;" >> /etc/nginx/nginx.conf',
    unless  => 'grep "daemon off" /etc/nginx/nginx.conf',
  }
}


node 'node1' {
  webserver { 'hello node 1': }
}

node 'node2' {
  webserver { 'hello node 2': }
}
