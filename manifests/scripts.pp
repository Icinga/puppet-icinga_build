class icinga_build::scripts {
  file { '/var/lib/jenkins/jenkins-scripts':
    ensure  => 'directory',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    recurse => true,
    force   => true,
    purge   => true,
    source  => 'puppet:///modules/icinga_build/jenkins-scripts',
  }
}
