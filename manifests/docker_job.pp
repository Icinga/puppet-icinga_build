define icinga_build::docker_job (
  $ensure             = present,
  $os                 = undef, #from namevar
  $releases           = undef,
  $archs              = undef,
  $combination_filter = undef,
  $git_repo           = undef,
  $git_branch         = 'master',
  $custom_shell       = undef,
  $base_image         = $::icinga_build::docker_job::defaults::base_image,
  $build_image        = $::icinga_build::docker_job::defaults::build_image,
  $jenkins_label      = $::icinga_build::docker_job::defaults::jenkins_label,
  $docker_registry    = $::icinga_build::docker_job::defaults::docker_registry,
  $publish            = $::icinga_build::docker_job::defaults::publish,
  $parameters         = { },
) {
  validate_hash($parameters)

  $_parameters_internal = {
    'DOCKER_REGISTRY' => $docker_registry,
    'PUBLISH'         => {
      'type'    => 'Boolean',
      'default' => $publish,
    },
  }

  $_parameters = merge($_parameters_internal, $parameters)

  ensure_resource('icinga_build::folder', 'docker',
    {
      ensure      => present,
      description => 'Docker image build jobs',
      icon        => 'aggregate-status',
    }
  )

  unless $git_repo {
    $name_split = split($title, '-')
    if size($name_split) != 2 {
      fail('Name must be "$prefix-$os"')
    }

    if $os {
      $_os = $os
    } else {
      $_os = $name_split[0]
    }

    if $os == 'sles' {
      fail($_parameters)
    }
  }

  if $ensure == present {
    if $git_repo {
      $_config = template('icinga_build/jobs/docker_image_git.xml.erb')
    } else {
      $_config = template('icinga_build/jobs/docker_image.xml.erb')
    }
  } else {
    $_config = ''
  }

  jenkins_job { "docker/${title}":
    ensure => $ensure,
    config => $_config,
  }
}
