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
# @param views_hash     Configuration categorized views for the pipeline folder
#
class icinga_build::pipeline::defaults(
  $arch           = undef,
  $docker_image   = undef,
  $jenkins_label  = undef,
  $views_hash     = undef,
  $view_default   = undef,
  $aptly_server   = undef,
  $aptly_user     = undef,
  $aptly_password = undef,
  $docker_registry_credentials = undef,
) { }
