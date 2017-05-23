define icinga_build::pipeline::rpm (
  $pipeline,
  $product,
  $control_repo,
  $control_branch,
  $release_type,
  $ensure         = 'present',
  $os             = undef, # part of namevar
  $dist           = undef, # part of namevar
  $arch           = $icinga_build::pipeline::defaults::arch,
  $docker_image   = $icinga_build::pipeline::defaults::docker_image,
  $jenkins_label  = $icinga_build::pipeline::defaults::jenkins_label,
  $aptly_server   = $icinga_build::pipeline::defaults::aptly_server,
  $aptly_user     = $icinga_build::pipeline::defaults::aptly_user,
  $aptly_password = $icinga_build::pipeline::defaults::aptly_password,
  # TODO: remove deprecated
  $use_epel       = undef,
) {
  validate_re($ensure, '^(present|absent)$')

  validate_array($arch)
  validate_string($docker_image, $jenkins_label)

  unless $arch and $docker_image and $jenkins_label and $aptly_server {
    fail('Please ensure to configure icinga_build::pipeline::defaults, or add the parameters directly')
  }

  $_name = regsubst($name, "^${pipeline}-", '')

  if $os and $dist {
    $_os = $os
    $_dist = $dist
  } elsif $_name =~ /^([\w\d\._]+)-([\w\d\._\-]+)$/ {
    $_os = $1
    $_dist = $2
  } else {
    fail("Can not parse os/dist from name: ${name}")
  }

  validate_string($_os, $_dist)

  $_docker_image = regsubst(regsubst($docker_image, '{os}', $_os), '{dist}', $_dist)
  $_docker_image_source = regsubst($_docker_image, '{arch}', $arch[0])
  $_docker_image_binary = regsubst($_docker_image, '{arch}', '$arch')
  $_docker_image_test = regsubst($_docker_image, '{arch}', '$arch')
  $_docker_image_publish = regsubst($_docker_image, '{arch}', $arch[0])

  $_source_job = "rpm-${_os}-${_dist}-0source"
  $_binary_job = "rpm-${_os}-${_dist}-1binary"
  $_test_job   = "rpm-${_os}-${_dist}-2test"
  $_publish_job     = "rpm-${_os}-${_dist}-3-publish"
  $_publish_job_old = "rpm-${_os}-${_dist}-3publish"
  $_publish_type = 'rpm'

  jenkins_job { "${pipeline}/${_source_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/rpm_source.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_binary_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/rpm_binary_matrix.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_test_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/rpm_test_matrix.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_publish_job_old}":
    ensure => absent,
  }

  jenkins_job { "${pipeline}/${_publish_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/rpm_publish.xml.erb'),
  }

  jenkins_job { "${pipeline}/rpm-${_os}-${_dist}":
    ensure => absent,
    config =>  template('icinga_build/jobs/pipeline_multi_job.xml.erb'),
  }
}
