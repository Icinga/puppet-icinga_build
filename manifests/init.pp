class icinga_build(
  $ssh_private_key = undef,
) {
  contain ::jenkins
  contain ::jenkins::cli_helper
  contain ::jenkins::cli::config

  contain ::icinga_build::scripts

  create_resources('icinga_build::folder', hiera_hash('icinga_build::folder', {}))
  create_resources('icinga_build::job',    hiera_hash('icinga_build::job', {}))
  create_resources('jenkins::plugin',      hiera_hash('jenkins::plugin', {}))

  if $ssh_private_key {
    file { 'jenkins ssh dir':
      ensure => directory,
      path   => '/var/lib/jenkins/.ssh',
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0700',
    }

    file { 'jenkins ssh key':
      ensure  => file,
      path    => '/var/lib/jenkins/.ssh/id_rsa',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $ssh_private_key,
      mode    => '0600',
    }
  }
}
