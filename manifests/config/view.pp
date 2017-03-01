define icinga_build::config::view (
  $conf,
  $version,
) {
  fail('Not yet correctly implemented')
  $value = 'regex'

  concat::fragment{ "config.xml view ${name}":
    target  => $conf,
    order   => 61,
    content => "<org.jenkinsci.plugins.categorizedview.CategorizedJobsView plugin=\"categorized-view@${version}\">
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
  <includeRegex>${value}</includeRegex>
  <recurse>true</recurse>
  <groupingRules/>
  <categorizationCriteria/>
</org.jenkinsci.plugins.categorizedview.CategorizedJobsView>",
  }
}
