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


## Maintainers

This repository is maintained by: Gareth Rushgrove <gareth@puppet.com>.
