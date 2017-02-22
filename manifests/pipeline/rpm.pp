define icinga_build::pipeline::rpm (
  $pipeline,
  $product,
  $control_repo,
  $control_branch,
  $os            = undef, # part of namevar
  $dist          = undef, # part of namevar
  $arch          = $icinga_build::pipeline::defaults::arch,
  $docker_image  = $icinga_build::pipeline::defaults::docker_image,
  $jenkins_label = $icinga_build::pipeline::defaults::jenkins_label,
  $use_epel      = false,
) {
  validate_array($arch)
  validate_string($docker_image, $jenkins_label)

  unless $arch and $docker_image and $jenkins_label {
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

  $_docker_image = regsubst(regsubst($docker_image, '{os}', $_os), '{dist}', $_dist)
  $_docker_image_source = regsubst($_docker_image, '{arch}', $arch[0])
  $_docker_image_binary = regsubst($_docker_image, '{arch}', '$arch')
  $_docker_image_test = regsubst($_docker_image, '{arch}', '$arch')

  $_source_job = "rpm-${_os}-${_dist}-0source"
  $_binary_job = "rpm-${_os}-${_dist}-1binary"
  $_test_job   = "rpm-${_os}-${_dist}-2test"

  $_use_epel = $use_epel

  jenkins_job { "${pipeline}/${_source_job}":
    config => template('icinga_build/jobs/rpm_source.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_binary_job}":
    config => template('icinga_build/jobs/rpm_binary_matrix.xml.erb'),
  }

  jenkins_job { "${pipeline}/${_test_job}":
    config => template('icinga_build/jobs/rpm_test_matrix.xml.erb'),
  }

  # TODO: release
}
