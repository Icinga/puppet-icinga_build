Icinga Build Puppet module
==========================

[![Build Status](https://travis-ci.org/Icinga/puppet-icinga_build.svg?branch=master)](https://travis-ci.org/Icinga/puppet-icinga_build)

Managing the Icinga Build system, taking care of:

* Packaging jobs for Debian, RedHat, SuSE (and alike)
* Build jobs for specific OSes (Windows, ...)

We currently build on [Jenkins], with [Jenkins slaves] running in [Docker].

Also see [icinga-build-vagrant].

## Using the module

To set up the Jenkins, and our build scripts, just use:

``` puppet
include ::icinga_build
```

TODO: fill me

## Build jobs and configuration

TODO

## License

    Copyright (C) 2012-2017 Icinga Development Team <info@icinga.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[Jenkins]: https://jenkins.io
[Jenkins slaves]: https://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds
[Docker]: https://www.docker.com
[icinga-build-vagrant]: https://github.com/Icinga/icinga-build-vagrant
