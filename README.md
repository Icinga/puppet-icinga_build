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

The module base takes care about:

* Jenkins + CLI
* Icinga specific scripts (legacy)
* SSH private key of Jenkins

With Hiera hashes the following resources can be created:

* `icinga_build::folder` - Wrapper for Folder Jobs
* `icinga_build::job` - Wrapper for `jenkins::job`
* `icinga_build::pipeline`
* `jenkins::plugin`
* `jenkins::docker_job`

## Build jobs and configuration

### Folder

``` puppet
icinga_build::folder { 'docker':
  description => 'My fancy folder',
}
```

### Job

This extends the default `jenkins::job` with templates and custom parameters.

``` puppet
icinga_build::job { 'icinga2-test':
  template => 'icinga_build/jobs/icinga2-test.sh.erb',
  params   => {
    test => true,
  },
  folder   => 'test',
}
```

### Pipeline

Is a specific define type to support our Package build pipelines.

This takes care about:

* Creates a folder for the pipeline
* Deb jobs: source, binary, test and publish
* RPM jobs in the same way

Here is a brief example:

``` puppet
icinga_build::pipeline { 'icinga2-snapshot':
  control_repo   => 'https://github.com/Icinga/icinga-packaging.git',
  control_branch => 'snapshot',
  matrix_deb     => {
    'debian-jessie' => {},
    'debian-wheezy' => {},
    'ubuntu-xenial' => {
      use => 'ubuntu',
    },
    'ubuntu-trusty' => {
      use => 'ubuntu',
    },
  },
  matrix_rpm => {
    'centos-6' => {},
    'centos-7' => {
      arch     => ['x86_64'],
    },
  },
}
```

## Docker Job

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
