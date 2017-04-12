class icinga_build::scripts {
  File {
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
  }

  file { '/var/lib/jenkins/jenkins-scripts':
    ensure  => 'directory',
    recurse => true,
    force   => true,
    purge   => true,
    source  => 'puppet:///modules/icinga_build/jenkins-scripts',
  }

  file { 'jenkins helper plugins-yaml.sh':
    ensure => file,
    path   => '/var/lib/jenkins/plugins-yaml.sh',
    source => 'puppet:///modules/icinga_build/helpers/plugins-yaml.sh',
  }
}
