define icinga_build::job (
  $template,
  $ensure  = 'present',
  $params  = undef,
  $jobname = $title,
  $enabled = true,
) {
  include ::jenkins

  if $template =~ /^jenkins\/icinga\// {
    $_template = regsubst($template, '^jenkins/icinga/', 'icinga_build/jobs/')
  } else {
    $_template = $template
  }

  jenkins::job { $title:
    ensure  => $ensure,
    config  => template($_template),
    jobname => $jobname,
    enabled => $enabled,
  }
}
