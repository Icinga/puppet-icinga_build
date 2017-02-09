# Defaults for all icinga_build::pipeline defined types
#
# @example You can use it like this
#   class { 'icinga_build::pipeline::defaults':
#     docker_image => 'private-registry:5000/icinga/{os}-{dist}-{arch}',
#     jenkins_label
#   }
#
# Or set the params via hiera, the class gets inherited by the defined types.
#
# @param jenkins_label  The slave label in Jenkins to bind the job to
# @param docker_image   Docker image to build with, the following patterns get replaced: {os}, {dist}, {arch}
#
class icinga_build::pipeline::defaults(
  $docker_image  = undef,
  $jenkins_label = undef,
) {}
