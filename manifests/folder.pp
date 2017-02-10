define icinga_build::folder (
  $ensure      = 'present',
  $description = '',
  $views_xml   = undef,
) {
  jenkins_job { $title:
    ensure => $ensure,
    name   => $name,
    config => template('icinga_build/jobs/folder.xml.erb'),
    enable => false, # folders are inactive internally
  }
}
