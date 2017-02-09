define icinga_build::pipeline::deb (
  $pipeline,
  $product,
  $control_repo,
  $control_branch,
  $use           = undef,
  $os            = undef, # part of namevar
  $dist          = undef, # part of namevar
  $arch          = ['x86_64', 'i386'],
  $docker_image  = $icinga_build::pipeline::defaults::docker_image,
  $jenkins_label = $icinga_build::pipeline::defaults::jenkins_label,
) {
  validate_array($arch)
  validate_string($docker_image, $jenkins_label)

  unless $docker_image and $jenkins_label {
    fail('Please ensure to configure icinga_build::pipeline::defaults, or add the parameters directly')
  }

  if $os and $dist {
    $_os = $os
    $_dist = $dist
  } elsif $name =~ /-([\w\d\._]+)-([\w\d\._]+)$/ {
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

  $_docker_image_source = regsubst(regsubst(regsubst($docker_image, '{os}', $_os), '{dist}', $_dist), '{arch}', $arch[0])

  jenkins_job { "${pipeline}/deb-${_os}-${_dist}-source":
    config => template('icinga_build/jobs/deb_source.xml.erb'),
  }

  # TODO: binary
  # TODO: test
  # TODO: release
}
