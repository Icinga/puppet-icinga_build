class icinga_build(
  $ssh_private_key                      = undef,
  $config_auth_security                 = 'none',
  $config_auth_ldap_server              = '',
  $config_auth_ldap_rootdn              = '',
  $config_auth_ldap_noinferrootdn       = false,
  $config_auth_ldap_usersearchbase      = 'ou=user',
  $config_auth_ldap_usersearch          = 'uid={0}',
  $config_auth_ldap_groupseachbase      = 'ou=groups',
  $config_auth_ldap_filter              = [],
  $config_auth_ldap_ldap_managerdn      = '',
  $config_auth_ldap_managerpassword     = '',
  $config_auth_ldap_disablemailresolver = false,
  $config_auth_ldap_displaynameattr     = 'displayname',
  $config_auth_ldap_displaymailattr     = 'mail',
  ) {
  contain ::jenkins
  contain ::jenkins::cli_helper
  contain ::jenkins::cli::config

  contain ::icinga_build::scripts
  contain ::icinga_build::config

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
