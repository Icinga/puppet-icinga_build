class icinga_build::config {
  $conf = 'icinga_build config.xml'
  concat { $conf:
    owner => 'jenkins',
    group => 'jenkins',
    mode  => '0644',
    path  => '/var/lib/jenkins/config.xml',
  }

  concat::fragment{ 'config.xml conf_header':
    target  => $conf,
    content => "<?xml version='1.0' encoding='UTF-8'?>\n<hudson>\n",
    order   => '01',
  }

  case $icinga_build::config_auth_security {
    default, 'none' : {
      concat::fragment{ 'config.xml conf_security':
        target  => $conf,
        content => "<useSecurity>false</useSecurity>\n",
        order   => '50',
      }
    }
    'ldap' : {
      #validate_string($icinga_build::ldap_server)
      #validate_re($icinga_build::irgendwas, '^(abc|def)$')

      concat::fragment { 'config.xml security ldap':
        target  => $conf,
        content => template('icinga_build/config/auth_ldap.xml.erb'),
        order   => '50',
      }
    }
  }

  concat::fragment { 'config.xml views header':
    target  => $conf,
    order   => 60,
    content => '<views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>',
  }

  concat::fragment { 'config.xml views footer':
    target  => $conf,
    order   => 70,
    content => '</views>',
  }

  concat::fragment{ 'config.xml conf_rest':
    target => $conf,
    source => 'puppet:///modules/icinga_build/config.xml',
    order  => '98',
  }

  concat::fragment{ 'config.xml conf_footer':
    target  => $conf,
    content => '</hudson>',
    order   => '99',
  }
}
