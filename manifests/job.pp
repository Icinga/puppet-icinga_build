define icinga_build::job (
  $template,
  $ensure  = 'present',
  $params  = undef,
  $jobname = $title,
  $enabled = true,
  $folder  = undef,
) {
  include ::jenkins

  $name_split = split($jobname, '/')

  if size($name_split) > 2 {
    fail('Only a folder depth of 1 is supported!')
  }

  if size($name_split) == 2 and $folder {
    fail('You can only specify folder in jobname *OR* folder')
  }

  if $folder {
    $_folder = $folder
    $_jobname = "${folder}/${jobname}"
  } elsif size($name_split) > 1 {
    $_folder = $name_split[0]
    $_jobname = $jobname
  } else {
    $_folder = undef
    $_jobname = $jobname
  }

  # Helper to handle old template paths
  # TODO: remove when migrated to new job structure
  if $template =~ /^jenkins\/icinga\// {
    $_template = regsubst($template, '^jenkins/icinga/', 'icinga_build/jobs/')
  } else {
    $_template = $template
  }

  if $_folder {
    Icinga_build::Folder[$_folder] -> Icinga_build::Job[$title]
  }

  jenkins_job { $title:
    ensure => $ensure,
    name   => $_jobname,
    enable => $enabled,
    config => template($_template),
  }
}
