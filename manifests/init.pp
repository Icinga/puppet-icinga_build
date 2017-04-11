class icinga_build (
  $ssh_private_key = '',
  $ssh_public_key  = '',
) {
  contain ::jenkins
  contain ::jenkins::cli_helper
  contain ::jenkins::cli::config

  contain ::icinga_build::scripts

  include ::icinga_build::pipeline::defaults

  create_resources('icinga_build::folder', hiera_hash('icinga_build::folder', {}))
  create_resources('icinga_build::job',    hiera_hash('icinga_build::job', {}))
  create_resources('icinga_build::pipeline', hiera_hash('icinga_build::pipeline', {}))
  create_resources('jenkins::plugin',      hiera_hash('jenkins::plugin', {}))
  create_resources('icinga_build::docker_job',  hiera_hash('icinga_build::docker_job', {}))

  if $ssh_private_key or $ssh_public_key {
    file { 'jenkins ssh dir':
      ensure => directory,
      path   => '/var/lib/jenkins/.ssh',
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0700',
    }

    file { 'jenkins id_rsa':
      ensure  => file,
      path    => '/var/lib/jenkins/.ssh/id_rsa',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $ssh_private_key,
      mode    => '0600',
    }
    file { 'jenkins id_rsa.pub':
      ensure  => file,
      path    => '/var/lib/jenkins/.ssh/id_rsa.pub',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $ssh_public_key,
      mode    => '0644',
    }
  }

  if $ssh_public_key {
    # configure Jenkins user to manage locally
    file { 'jenkins users':
      ensure => directory,
      path   => '/var/lib/jenkins/users',
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0640',
    }
    file { 'jenkins user puppet':
      ensure => directory,
      path   => '/var/lib/jenkins/users/puppet',
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0640',
    }

    Package['jenkins'] ->
    file { 'jenkins user puppet config.xml':
      ensure  => file,
      path    => '/var/lib/jenkins/users/puppet/config.xml',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      content => template('icinga_build/puppet-user.xml'),
    } ~> Service['jenkins']
  }
}
