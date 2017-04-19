define icinga_build::docker_job (
  $os                 = undef, #from namevar
  $releases           = undef,
  $archs              = undef,
  $combination_filter = undef,
  $base_image         = $::icinga_build::docker_job::defaults::base_image,
  $jenkins_label      = $::icinga_build::docker_job::defaults::jenkins_label,
  $docker_registry    = $::icinga_build::docker_job::defaults::docker_registry,
  $publish            = $::icinga_build::docker_job::defaults::publish,
  $parameters         = { },
) {
  validate_hash($parameters)

  $name_split = split($title, '-')
  if size($name_split) != 2 {
    fail('Name must be "$prefix-$os"')
  }

  if $os {
    $_os = $os
  } else {
    $_os = $name_split[0]
  }

  $_parameters_internal = {
    'DOCKER_REGISTRY' => $docker_registry,
    'PUBLISH'         => {
      'type'    => 'Boolean',
      'default' => $publish,
    },
  }

  $_parameters = merge($_parameters_internal, $parameters)

  if $os == 'sles' {
    fail($_parameters)
  }

  jenkins_job { "docker/${title}":
    config => template('icinga_build/jobs/docker_image.xml.erb'),
  }
}
