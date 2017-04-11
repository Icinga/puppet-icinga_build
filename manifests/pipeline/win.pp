define icinga_build::pipeline::win (
  $pipeline,
  $product,
  $control_repo,
  $control_branch,
  $release_type,
  $os             = undef, # part of namevar
  $dist           = undef, # part of namevar
  $arch           = $icinga_build::pipeline::defaults::arch,
#  $docker_image   = $icinga_build::pipeline::defaults::docker_image,
  $jenkins_label  = $icinga_build::pipeline::defaults::jenkins_label,
  $aptly_server   = $icinga_build::pipeline::defaults::aptly_server,
  $use_epel       = false,
) {
  validate_array($arch)
  validate_string($docker_image, $jenkins_label)

  unless $arch and $docker_image and $jenkins_label and $aptly_server {
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

  $_source_job  = "win-${_os}-${_dist}-0source"
  $_binary_job  = "win-${_os}-${_dist}-1binary"
  $_test_job    = "win-${_os}-${_dist}-2test"
  $_publish_job = "win-${_os}-${_dist}-3publish"

  $_use_epel = $use_epel

  jenkins_job { "${pipeline}/${_binary_job}":
    config => template('icinga_build/jobs/win_binary_matrix.xml.erb'),
  }

  jenkins_job { "${pipeline}/win-${_os}-${_dist}":
    config =>  template('icinga_build/jobs/pipeline_multi_job.xml.erb'),
  }
}
