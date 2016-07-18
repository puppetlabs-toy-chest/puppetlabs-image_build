# It's common for systemd services to need to refresh systemctl
# by always returning true we avoid issues with what in the context
# of this module are unhelpful execs
file { '/bin/systemctl':
  ensure => link,
  target => '/bin/true',
}

# In cases where included modules explicitly set the provider
# the resource default won't work, so you may need to
# drop down and use resource collectors
Service <| |> { provider => dummy }

class { 'elasticsearch': }
elasticsearch::instance { 'es-01':
  status => 'unmanaged',
}

$elasticsearch_cmd = "#!/bin/bash -e\n/usr/share/elasticsearch/bin/elasticsearch -Des.default.path.conf=/etc/elasticsearch/es-01/ -Des.insecure.allow.root=true"
file { '/docker-entrypoint.sh':
  content => $elasticsearch_cmd,
  mode    => '0744',
}

