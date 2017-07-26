##2017-07-26 - Version 0.6.0

* Adds the ability to specify a Docker network for the docker build
  command
* Can now skip the installation of Puppet if the base image already has
  it installed

This release also fixes an issue where a failure in the Puppet run
during image build would not propogate the error so the command line
exits with a non-zero exit code.


##2017-07-25 - Version 0.5.0

Adding a couple of user requested features, specifically the ability to
disable the diff output, and also the ability to enable full debug
output from the Puppet process run inside the container during build


##2017-07-25 - Version 0.4.0


This release adds support for using the Puppet 5 repositories, and
switches the default Puppet used to build images to Puppet 5.


##2017-03-22 - Version 0.3.0

This release includes some minor features and several bug fixes,
including:

* Adds the ability to specify a list of volumes for the image
* Fix a bug which meant building Centos images didn't work as expected

Thanks to community member @luckyraul for the volumes addition, and to
@aaron-grewell for reporting and testing the fix for the Centos issue.


##2017-02-21 - Version 0.2.0

This release includes some minor features and several bug fixes,
including:

* Fail the build if Puppet apply fails
* Support passing a directory of manifests as well as a single manifest
* Correctly discover more debian based images
* Initial support for passing in fact values
* Retain packages useful for r10k and git based Puppet modules
* Support passing an https proxy

Thanks to community members @gerardkok, @luckyraul, @arnd, @McSlow,
@jonnaladheeraj and @oc243 for input into this release.
