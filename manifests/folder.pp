define icinga_build::folder (
  $ensure      = 'present',
  $description = '',
) {
  # TODO: allow views via Hash
  $_views_xml = ''

  jenkins_job { $title:
    ensure => $ensure,
    name   => $name,
    config => template('icinga_build/jobs/folder.xml.erb'),
    enable => false, # folders are inactive internally
  }
}
