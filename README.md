# image_build

[![Puppet
Forge](https://img.shields.io/puppetforge/v/puppetlabs/image_build.svg)](https://forge.puppetlabs.com/puppetlabs/image_build)
[![Build
Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-image_build.png)](https://travis-ci.org/puppetlabs/puppetlabs-image_build)
[![Coverage
Status](https://coveralls.io/repos/github/puppetlabs/puppetlabs-image_build/badge.svg?branch=master)](https://coveralls.io/github/puppetlabs/puppetlabs-image_build?branch=master)

[Module description]: #module-description
[Setup]: #setup
[Usage]: #usage
[Reference]: #reference
[A hello world example]: #a-hello-world-example---nginx
[Involving hiera]: #involving-hiera---elasticsearch
[Building multiple images from one manifest]: #building-multiple-images-from-one-manifest
[Using a Puppet Master]: #using-a-puppet-master
[Minimizing image size with Rocker]: #minimizing-image-size-with-rocker
[Building ACI images]: #building-aci-images
[Limitations]: #limitations
[Maintainers]: #maintainers

#### Table of Contents

1. [Module description - What is the image_build module, and what does it
   do?][Module description]
2. [Setup - The basics of getting started with image_build][Setup]
3. [Usage - How to build Docker containers with Puppet][Usage]
    - [A hello world example][A hello world example]
    - [Involving hiera][Involving hiera]
    - [Building multiple images from one manifest][Building multiple images from one manifest]
    - [Using a Puppet Master][using a Puppet Master]
    - [Minimizing image size with Rocker][Minimizing image size with Rocker]
    - [Building ACI images][Building ACI images]
4. [Reference - Sample help output from the tool][Reference]
5. [Limitations - OS compatibility, etc.][Limitations]
6. [Maintainers - who maintains this project][Maintainers]


## Module description

The basic purpose of `image_build` is to enable building various images,
including Docker images, from Puppet code. There are two main cases
where this can be useful:

1. You have an existing Puppet codebase and you're moving some of your
   services to using containers. By sharing the same code between
   container and non-container based infrastructure you can cut down on
   duplication of effort, and take advantage of work you've already
   done.
2. You're building a lot of images, but scaling Dockerfile means either
   a complex hierachy of images or copy-and-pasting snippets between
   many individual Dockerfiles. `image_build` allows for sharing common
   functionality as Puppet modules, and Puppet itself provides a rich
   domain-specific language for declarative composition of images.


## Setup

`puppetlabs/image_build` is a Puppet Module and is available on the Forge.

The following should work in most cases:

```
puppet module install puppetlabs/image_build
```

You don't need any additional gems installed unless you are looking to
work on developing the module. All you need is a working Docker environment or
`acbuild`, for which I'd recommend Docker for Mac or Docker for Windows
or just installing Docker if you're on Linux. For acbuild you can use
the [rkt module](https://forge.puppet.com/puppetlabs/rkt).

## Usage

With the module installed you should have access to two new puppet
commands; `puppet docker` and `puppet aci`. These have two subcommands,
one will trigger a build of an image, the other can be used to output
the intermediary dockerfile or shell script.

The examples directory contains a set of examples for experimenting with.
Simply open up `examples/nginx` and run:

    puppet docker build

The above is the simplest example of a build. Some settings are provided
in the accompanying `metadata.yaml` file, while others are defaults
specific to the tool. You can change values in the metadata file (useful
for version control) or you can override those values on the command
line.

    puppet docker build --image-name puppet/sample --cmd nginx --expose 80

See the full help page for other arguments for specifying different
base images, setting a maintainer, using Rocker instead of Docker for the
build and much more.

    puppet docker build --help

You can also output the intermediary dockerfile using another
subcommand. This is useful for both debugging and if you want to do
something not natively supported by the tool.

    puppet docker dockerfile


### A hello world example - Nginx

Lets see a simple hello world example. We'll create a Docker image
running Nginx and serving a simple text file.

First lets use a few Puppet modules from the Forge. We'll use the
existing [nginx module](https://forge.puppet.com/puppet/nginx) and
we'll specify it's dependencies. We're also using
[dummy_service](https://forge.puppet.com/puppetlabs/dummy_service) to
ignore service resources in the Nginx module.

```
$ cat Puppetfile
forge 'https://forgeapi.puppetlabs.com'

mod 'puppet/nginx'
mod 'puppetlabs/stdlib'
mod 'puppetlabs/concat'
mod 'puppetlabs/apt'
mod 'puppetlabs/dummy_service'
```

Then lets write a simple manifest. Disabling nginx daemon mode isn't
supported by the module yet so we drop a file in place. Have a look at
`manifests/init.pp`:

```puppet
include 'dummy_service'

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

And finally lets store the metadata in a file rather than pass on the
command line. Take a look at `metadata.yaml`:

```yaml
cmd: nginx
expose: 80
image_name: puppet/nginx
```

Now lets build a Docker image. Note that you'll need docker available on
your host to do so, along with the `image_build` module installed.

```
puppet docker build
```

And finally lets run our new image. We expose the webserver on port 8080
to the local host.

```
$ docker run -d -p 8080:80 puppet/nginx
83d5fbe370e84d424c71c1c038ad1f5892fec579d28b9905cd1e379f9b89e36d
$ curl http://0.0.0.0:8080
Hello Puppet and Docker%
```

### Involving hiera - Elasticsearch

The Elasticsearch example is similar to the above, with a few additional
features demonstrated. In particular the use of Hiera to provide
additional context for the Puppet build. You can find this in the
`examples/elasticsearch` directory.

```
puppet docker build manifests/init.pp --image-name puppet/es --expose 9200 --cmd /docker-entrypoint.sh
```

### A note on options with multiple arguments

Several of the arguments to `image_build` can take a list of values.
This is done by passing in comma separated values. For instance, to
specify an `ENTRYPOINT` like so:

```
ENTRYPOINT ["nginx", "-g", "daemon off"]
```

You can pass the following on the commandline:

```
--entrypoint nginx,'-g','daemon off'
```

### Building multiple images from one manifest

One advantage of using Puppet for building Docker images is you are
removed from the need to have a single Dockerfile per image. Meaning a
single repository of Puppet code can be used to describe multiple
images. This makes ensuring all images use (for example) the same
repositories or same hardening scripts much easier to enforce. Change
code in one place and rebuild multiple images.

Describing multiple images in Puppet is done using the existing `node`
resource in your manifest. For instance:

```puppet
node 'node1' {
  webserver { 'hello node 1': }
}

node 'node2' {
  webserver { 'hello node 2': }
}
```

You can then select which image to build when running the build command,
by explicitly passing the `image-name`.

    puppet docker build --image-name puppet/node1

The match for the node resource in the Puppet code is done without the
repository name, in this case the `puppet/` before `node1`.

Note that you may want different metadata for different images.
`image_build` will attempt to detect additional metadata in the
`metadata` folder, and will merge items from `metadata/metadata.yaml`
with node specific metadata, for instance from `metadata/node1.yaml`

You can see an example of this settup in the `examples/multi` directory.


### Using a Puppet Master

The above examples all use local manifests copied to the image during
build, but `image_build` also supports using a Puppet Master. You can
provide metadata via a local metadata file or directory, or by passing
command line arguments to the build command as shown in the examples
above. The only change is passing `--master` like so.

    puppet docker dockerfile --master puppet.example.com --image-name puppet/node1 --expose 80 --cmd nginx

The hostname passed to the Puppet Master will take the form
node1.{datetime}.dockerbuilder. This means you can match on that pattern
in your manifests, for instance like so:

```puppet
node /^node1/ {
  webserver { 'hello node 1': }
}
```

A worked example is provided in the `examples/master` folder. You can
either upload this to an existing Puppet Master or Puppet Enterprise
install, or run a new local master using Docker.

First install the dependent modules into the local environment:

    r10k puppetfile install --moduledir code/environments/production/modules

Create an `autosign.conf` file with the following:

```
*.dockerbuilder.*
```

Then, from the `examples/master` folder, use Docker to run an instance
of Puppet Server:

    docker run --name puppet -P --hostname puppet -v $(pwd)/code:/etc/puppetlabs/code -v $(pwd)/autosign.conf:/etc/puppetlabs/puppet/autosign.conf puppet/puppetserver-standalone

Determine the port on which the Puppet Server is exposed locally:

    docker port puppet

You'll also need the IP address of your local machine. Replace the {ip}
and {port} in the following with your own values.

    puppet docker dockerfile --master {ip}:{port} --image-name puppet/node1 --expose 80 --cmd nginx

This should use the code on the Puppet Master to build the image.


### Minimizing image size with Rocker

`image_build` supports using the
[Rocker](https://github.com/grammarly/rocker) build tool in place of the
standard Docker build command. The Rocker output provides a little more
detail about the build process, but also allows for mounting of folders
at build time which minimizes the size of the resulting image.

    puppet docker build --rocker

Note that when using Rocker the Puppet tools are not left in the final
image, reducing it's file size.


### Building ACI images

As well as Docker support, `image_build` also experimentally supports building
[ACI](https://github.com/appc/spec/blob/master/spec/aci.md) compatible
images for use with Rkt or other supported runtimes. This works in the
same manner as above. The following command should generate a shell
script which, when run, generates an ACI:

    puppet aci script

And if you simply want to build the ACI directly you can just run:

    puppet aci build


## Reference

```
$ puppet docker --help
USAGE: puppet docker <action> [--from STRING]
[--maintainer STRING]
[--os STRING]
[--os-version STRING]
[--puppet-agent-version STRING]
[--r10k-version STRING]
[--module-path PATH]
[--expose STRING]
[--cmd STRING]
[--entrypoint STRING]
[--labels KEY=VALUE]
[--rocker]
[--[no-]inventory]
[--hiera-config STRING]
[--hiera-data STRING]
[--image-user STRING]
[--puppetfile STRING]
[--image-name STRING]
[--config-file STRING]
[--config-directory STRING]
[--master STRING]
[--puppet-env STRING]

Build Docker images and Dockerfiles using Puppet code

OPTIONS:
  --render-as FORMAT             - The rendering format to use.
  --verbose                      - Whether to log verbosely.
  --debug                        - Whether to log debug information.
  --cmd STRING                   - The default command to be executed by the
                                   resulting image
  --config-directory STRING      - A folder where metadata can be loaded from
  --config-file STRING           - A configuration file with all the metadata
  --entrypoint STRING            - The default entrypoint for the resulting
                                   image
  --expose STRING                - A list of ports to be exposed by the
                                   resulting image
  --from STRING                  - The base docker image to use for the
                                   resulting image
  --hiera-config STRING          - Hiera config file to use
  --hiera-data STRING            - Hieradata directory to use
  --image-name STRING            - The name of the resulting image
  --image-user STRING            - Specify a user to be used to run the
                                   container process
  --[no-]inventory               - Enable or disable the generation of an
                                   inventory file at /inventory.json
  --labels KEY=VALUE             - A set of labels to be applied to the
                                   resulting image
  --maintainer STRING            - Name and email address for the maintainer of
                                   the resulting image
  --master STRING                - A Puppet Master to use for building images
  --module-path PATH             - A path to a directory containing a set of
                                   modules to be copied into the image
  --network STRING               - The Docker network to pass along to the
                                   docker build command
  --os STRING                    - The operating system used by the image if not
                                   autodetected
  --os-version STRING            - The version of the operating system used by
                                   the image if not autodetected
  --puppet-agent-version STRING  - Version of the Puppet Agent package to
                                   install
  --puppet-debug                 - Pass the debug flag to the Puppet process
                                   used to build the container image
  --puppet-env STRING		 - Puppet environment used. Defaults to production
  --puppetfile STRING            - Enable use of Puppetfile to install
                                   dependencies during build
  --r10k-version STRING          - Version of R10k to use for installing modules
                                   from Puppetfile
  --rocker                       - Use Rocker as the build tool
  --[no-]show-diff               - Enable or disable showing the diff when
                                   running Puppet to build the image
  --skip-puppet-install          - If the base image already contains Puppet we
                                   can skip installing it
  --volume STRING                - A list of volumes to be added to the
                                   resulting image

ACTIONS:
  build         Build a Docker image from Puppet code
  dockerfile    Generate a Dockerfile which will run the specified Puppet code

See 'puppet man docker' or 'man puppet-docker' for full help.
```

## Limitations

The module currently does not support building Windows containers, or
building containers from a Windows machine. We'll be adding support for
these in the future.

The inventory functionality does not work correctly on Centos 6 based
images, so if you're using Centos 6 then you need to pass the
`--no-inventory` flag.

## Maintainers

This repository is maintained by: Gareth Rushgrove <gareth@puppet.com>.
