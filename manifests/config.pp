class icinga_build::config {
  $conf = 'icinga_build config.xml'
  concat { $conf:
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0644',
    path   => '/var/lib/jenkins/config.xml'
  }

  concat::fragment{ 'config.xml conf_header':
    target  => $conf,
    content => "<?xml version='1.0' encoding='UTF-8'?>\n<hudson>\n",
    order   => '01'
  }

  case $icinga_build::config_auth_security {
    'none' : {
      concat::fragment{ 'config.xml conf_security':
        target  => $conf,
        content => "<useSecurity>false</useSecurity>\n",
        order   => '50',
      }
    }
    'ldap' : {
#      validate_string($icinga_build::ldap_server)
#      validate_re($icinga_build::irgendwas, '^(abc|def)$')

      concat::fragment { 'config.xml security ldap':
        target  => $conf,
        content => template('icinga_build/config/auth_ldap.xml.erb'),
        order   => '50',
      }
    }
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

define icinga_build::config::authentication_ldap(
  $conf,
  $ldap_version,
  $ldap_server,
  $ldap_rootDN,
  $ldap_managerDN,
  $ldap_managerPasswordSecret,
  ) {

  $ldap_blob = "
"

  concat::fragment{ 'config.xml conf_authentication_ldap':
    target  => $conf,
    order   => 50,
    content => $ldap_blob,
  }
}

define icinga_build::config::views (
  $conf,
  $version,
  $views,
) {
  concat::fragment { "config.xml conf_views_header":
    target => $conf,
    order => 60,
    content => '<views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>',
  }
  

  #Needs future parser ;_;
  #  $views.each |$index, $value| {
  concat::fragment{ "config.xml conf_views_part_$index":
      target  => $conf,
      order   => 64,
      content => "<org.jenkinsci.plugins.categorizedview.CategorizedJobsView plugin=\"categorized-view@$version\">
  <owner class=\"hudson\" reference=\"../../..\"/>
  <name>Docker</name>
  <filterExecutors>false</filterExecutors>
  <filterQueue>false</filterQueue>
  <properties class=\"hudson.model.View\$PropertyList\"/>
  <jobNames>
    <comparator class=\"hudson.util.CaseInsensitiveComparator\"/>
  </jobNames>
  <jobFilters/>
  <columns>
    <hudson.views.StatusColumn/>
    <hudson.views.WeatherColumn/>
    <org.jenkinsci.plugins.categorizedview.IndentedJobColumn/>
    <hudson.views.LastSuccessColumn/>
    <hudson.views.LastFailureColumn/>
    <hudson.views.LastDurationColumn/>
    <hudson.views.BuildButtonColumn/>
  </columns>
  <includeRegex>$value</includeRegex>
  <recurse>true</recurse>
  <groupingRules/>
  <categorizationCriteria/>
</org.jenkinsci.plugins.categorizedview.CategorizedJobsView>",
  }
#  }

  concat::fragment { "config.xml conf_views_footer":
    target  => $conf,
    order   => 66,
    content => '</views>',
  }
}
