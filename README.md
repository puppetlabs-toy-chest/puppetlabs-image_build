Build Docker images from Puppet code.

_This is currently a very hacky prototype. The code quality is terrible,
nothing resemling tests can be found anywhere and if you try do anything
unexpected it will likely explode. If you make it past this statement
then any and all feedback is much appreciated._

## Usage

With the module installed you should have access to a new puppet
command, `puppet docker`. This has two subcommands, one will trigger a
build of an image, the other can be used to output the intermediary
dockerfile.

The example directory contains a simple example for experimenting with.
Simply enter that directory and run:

    puppet docker build manifests/init.pp --image-name puppet/sample

The above is the simplest example of a build. But the resulting image
won't have a default command, nor will it expose the correct ports for
the nginx example. We can fix that with a few extra arguments.

    puppet docker build manifests/init.pp --image-name puppet/sample --cmd nginx --expose 80

See the full help for other arguments for specificing a different
base image, setting a maintainer, using Rocker instead of Docker for the
build and much more.

    puppet docker build --help

You can also output the intermediary dockerfile using another
subcommand. This is useful for both debugging and if you want to do
something not natively supported by the tool.

    puppet docker dockerfile manifests/init.pp


## Examples

The module includes a few examples to help get you started. See the
examples directory for the accompanying code. Here's a simple hello
world example.


### Nginx

Lets see a simple hello world example. We'll create a Docker image
running Nginx and serving a simple text file.

First lets use a few Puppet modules from the Forge. We'll use the
existing [nginx module](https://forge.puppet.com/jfryman/nginx) and
we'll specify it's dependencies. We're also using
[dummy_service](https://forge.puppet.com/puppetlabs/dummy_service) to
ignore service resources in the Nginx module.

```
$ cat Puppetfile
forge 'https://forgeapi.puppetlabs.com'

mod 'jfryman/nginx'
mod 'puppetlabs/stdlib'
mod 'puppetlabs/concat'
mod 'puppetlabs/apt'
mod 'puppetlabs/dummy_service'
```

Then lets write a simple manifest. Disabling nginx daemon mode isn't
supported by the module yet so we drop a file in place.

```
$ cat manifests/init.pp
Service {
  provider => dummy
}

class { 'nginx': }

nginx::resource::vhost { 'default':
  www_root => '/var/www/html',
}

file { '/var/www/html/index.html':
  ensure  => present,
  content => 'Hello Puppet and Docker',
}

exec { 'Disable Nginx daemon mode':
  path    => '/bin',
  command => 'echo "daemon off;" >> /etc/nginx/nginx.conf',
  unless  => 'grep "daemon off" /etc/nginx/nginx.conf',
}
```

Now lets build a Docker image. Note that you'll need docker available on
your host to do so, along with the `docker_build` module installed.

```
puppet docker build manifests/init.pp --image-name puppet/nginx --expose 80 --cmd nginx
```

And finally lets run our new image. We expose the webserver on port 8080
to the local host.

```
$ docker run -d -p 8080:80 garethr/nginx-test
83d5fbe370e84d424c71c1c038ad1f5892fec579d28b9905cd1e379f9b89e36d
$ curl http://0.0.0.0:8080
Hello Puppet and Docker%
```

### Elasticsearch

The Elasticsearch example is similar to the above, with a few additional
features demonstrated. In particular the use of Hiera to provide
additional context for the Puppet build.

```
puppet docker build manifests/init.pp --image-name puppet/es --hiera --expose 9200 --cmd /docker-entrypoint.sh
```

## Help

```
$ puppet docker build --help
USAGE: puppet docker build [--image STRING]
[--maintainer STRING]
[--os STRING]
[--os-version STRING]
[--puppet-agent-version STRING]
[--r10k-version STRING]
[--expose STRING]
[--cmd STRING]
[--entrypoint STRING]
[--labels KEY=VALUE]
[--rocker]
[--disable-inventory]
[--image-name STRING]
<manifest>

Discovery resources (including packages, services, users and groups)

OPTIONS:
  --render-as FORMAT             - The rendering format to use.
  --verbose                      - Whether to log verbosely.
  --debug                        - Whether to log debug information.
  --cmd STRING                   - The default command to be executed by the
                                   resulting image
  --disable-inventory            - Enable advanced options and use Rocker as the
                                   build tool
  --entrypoint STRING            - The default entrypoint for the resulting
                                   image
  --expose STRING                - A list of ports to be exposed by the
                                   resulting image
  --hiera                        - Enable use of hiera during build
  --image STRING                 - The base docker image to use for the
                                   resulting image
  --image-name STRING            - The name of the resulting image
  --labels KEY=VALUE             - A set of labels to be applied to the
                                   resulting image
  --maintainer STRING            - Name and email address for the resulting
                                   image
  --os STRING                    - The operating system used by the image if not
                                   autodetected
  --os-version STRING            - The version of the operating system used by
                                   the image if not autodetected
  --puppet-agent-version STRING  - Version of the Puppet Agent package to
                                   install
  --puppetfile                   - Enable use of Puppetfile to install
                                   dependencies during build
  --r10k-version STRING          - Version of R10k to use for installing modules
                                   from Puppetfile
  --rocker                       - Enable advanced options and use Rocker as the
                                   build tool

See 'puppet man docker' or 'man puppet-docker' for full help.
```

## Maintainers

This repository is maintained by: Gareth Rushgrove <gareth@puppet.com>.
