define icinga_build::pipeline::deb (
  $pipeline,
  $product,
  $control_deb,
  $control_repo,
  $control_branch,
  $release_type,
  $ensure         = 'present',
  $use            = undef,
  $os             = undef, # part of namevar
  $dist           = undef, # part of namevar
  $parameters     = { },
  $arch           = $icinga_build::pipeline::defaults::arch,
  $docker_image   = $icinga_build::pipeline::defaults::docker_image,
  $jenkins_label  = $icinga_build::pipeline::defaults::jenkins_label,
  $aptly_server   = $icinga_build::pipeline::defaults::aptly_server,
  $aptly_user     = $icinga_build::pipeline::defaults::aptly_user,
  $aptly_password = $icinga_build::pipeline::defaults::aptly_password,
  $allow_release  = false,
  $upstream_repo   = undef,
  $upstream_branch = undef,
  $scm_trigger     = undef,
  $docker_registry_credentials = $icinga_build::pipeline::defaults::docker_registry_credentials,
) {
  validate_re($ensure, '^(present|absent)$')

  validate_array($arch)
  validate_string($docker_image, $jenkins_label)
  validate_bool($allow_release)

  unless $arch and $docker_image and $jenkins_label {
    fail('Please ensure to configure icinga_build::pipeline::defaults, or add the parameters directly')
  }

  if $release_type != 'release' {
    unless $upstream_repo and $upstream_branch {
      fail("${title}: You need to set \$upstream_repo and \$upstream_branch for non-release builds!")
    }

    validate_string($upstream_repo)
    validate_string($upstream_branch)
  }

  if $scm_trigger { validate_string($scm_trigger) }

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

  if $use {
    $_use = $use
  } else {
    $_use = $_dist
  }

  $_docker_image = regsubst(regsubst($docker_image, '{os}', $_os), '{dist}', $_dist)
  $_docker_image_source = regsubst($_docker_image, '{arch}', $arch[0])
  $_docker_image_binary = regsubst($_docker_image, '{arch}', '$arch')
  $_docker_image_test = regsubst($_docker_image, '{arch}', '$arch')
  $_docker_image_publish = regsubst($_docker_image, '{arch}', $arch[0])

  $_source_job = "deb-${_os}-${_dist}-0source"
  $_binary_job = "deb-${_os}-${_dist}-1binary"
  $_test_job   = "deb-${_os}-${_dist}-2test"
  $_publish_job = "deb-${_os}-${_dist}-3-publish"
  $_publish_job_old = "deb-${_os}-${_dist}-3publish"
  $_publish_type = 'deb'

  jenkins_job { "${pipeline}/${_source_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/deb_source.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_binary_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/deb_binary_matrix.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_test_job}":
    ensure => $ensure,
    config => template('icinga_build/jobs/deb_test_matrix.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_publish_job_old}":
    ensure => absent,
  }

  if $ensure == present and $release_type == 'dev' {
    $_publish_ensure = absent
  } else {
    $_publish_ensure = $ensure
  }

  jenkins_job { "${pipeline}/${_publish_job}":
    ensure => $_publish_ensure,
    config => template('icinga_build/jobs/deb_publish.xml.erb'),
  }

  jenkins_job { "${pipeline}/deb-${_os}-${_dist}":
    ensure => absent,
  }
}
