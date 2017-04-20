define icinga_build::folder (
  $ensure       = 'present',
  $description  = '',
  $view_default = undef,
  $views_xml    = undef,
  $icon         = 'folder',
) {
  validate_re($icon, '^(folder|aggregate-status)$')

  jenkins_job { $title:
    ensure => $ensure,
    name   => $name,
    config => template('icinga_build/jobs/folder.xml.erb'),
    enable => false, # folders are inactive internally
  }
}
