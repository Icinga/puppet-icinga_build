define icinga_build::docker_job (
  $os                 = undef, #from namevar
  $releases           = undef,
  $archs              = undef,
  $combination_filter = undef,
  $base_image         = $::icinga_build::docker_job::defaults::base_image,
  $jenkins_label      = $::icinga_build::docker_job::defaults::jenkins_label,
  $parameters         = {},
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

  jenkins_job { "docker/${title}":
    config => template('icinga_build/jobs/docker_image.xml.erb'),
  }
}
