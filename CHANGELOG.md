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
