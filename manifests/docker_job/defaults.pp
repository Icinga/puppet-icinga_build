# Defaults for all icinga_build::docker_job defined types
#
# @example You can use it like this
#   class { 'icinga_build::docker_job::defaults':
#     jenkins_label => 'docker-test',
#   }
#
# Or set the params via hiera, the class gets inherited by the defined types.
#
# @param jenkins_label  The slave label in Jenkins to bind the job to
#
class icinga_build::docker_job::defaults(
  $jenkins_label   = '',
  $base_image      = '',
  $build_image     = '',
  $docker_registry = '',
  $publish         = false,
) { }
