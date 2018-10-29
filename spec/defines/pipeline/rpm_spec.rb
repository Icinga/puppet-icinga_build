require 'spec_helper'

describe 'icinga_build::pipeline::rpm' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let :pre_condition do
        "class { 'icinga_build::pipeline::defaults':
          arch           => ['x86_64', 'x86'],
          jenkins_label  => 'docker-test',
          docker_image   => 'private-registry:5000/icinga/{os}-{dist}-{arch}',
          aptly_server   => 'http://localhost',
          aptly_user     => 'admin',
          aptly_password => 'admin',
        }"
      end

      context 'with a split control repo' do
        let :title do
          'icinga2-snapshot-centos-7'
        end

        let :params do
          {
            product:         'icinga2',
            pipeline:        'icinga2-snapshot',
            control_repo:    :undef,
            control_rpm:     'https://github.com/Icinga/rpm-icinga2.git',
            control_branch:  'snapshot',
            upstream_repo:   'https://github.com/Icinga/icinga2.git',
            upstream_branch: 'support/x.x',
            release_type:    'snapshot',
            docker_registry_credentials: 'yoloops'
          }
        end

        it { should compile.with_all_deps }

        # pre_condition
        it { should contain_class('icinga_build::pipeline::defaults') }

        it { should contain_icinga_build__pipeline__rpm('icinga2-snapshot-centos-7') }

        it do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-0source')
            .with_config(/<url>#{Regexp.escape(params[:control_rpm])}<.url>/)
            .with_config(/control_rpm="#{Regexp.escape(params[:control_rpm])}"/)
            .with_config(%r{BranchSpec.*\r?\n.*origin/support/x.x})
            .with_config(%r{<assignedNode>docker-test</assignedNode>})
            .with_config(%r{<image>private-registry:5000/icinga/centos-7-x86_64</image>})
            .with_config(%r{<projectNameList>\s*<string>rpm-centos-7-1binary</string>\s*</projectNameList>}m)
            .with_config(%r{<dockerRegistryCredentials>yoloops</dockerRegistryCredentials>})
            .with_config(/project="icinga2"/)
            .with_config(/os="centos"/)
            .with_config(/dist="7"/)
            .with_config(%r{upstream_branch="support/x.x"})
            .with_config(/rpmbuild --nodeps -bs/)
        end

        it do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-1binary')
            .with_config(/matrix-project/)
            .with_config(%r{<assignedNode>docker-test</assignedNode>})
            .with_config(%r{<image>private-registry:5000/icinga/centos-7-\$arch</image>})
            .with_config(%r{<projectNameList>\s*<string>rpm-centos-7-2test</string>\s*</projectNameList>}m)
            .with_config(%r{<upstreamProjects>rpm-centos-7-0source</upstreamProjects>})
            .with_config(%r{<hudson.matrix.TextAxis>\s*<name>arch</name>\s*<values>\s*<string>x86_64</string>\s*<string>x86</string>\s*</values>\s*</hudson.matrix.TextAxis>}m)
            .with_config(%r{<project>icinga2-snapshot/rpm-centos-7-0source</project>}) # copy artifacts from
            .with_config(%r{<dockerRegistryCredentials>yoloops</dockerRegistryCredentials>})
            .with_config(/project="icinga2"/)
            .with_config(/os="centos"/)
            .with_config(/dist="7"/)
            .without_config(/^arch=/)
            .with_config(/rpmbuild --rebuild/)
        end

        it 'should have a test job' do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-2test')
            .with_config(%r{<dockerRegistryCredentials>yoloops</dockerRegistryCredentials>})
            .with_config(/matrix-project/)
            .with_config(/project="icinga2"/)
            .with_config(/control_rpm="#{Regexp.escape(params[:control_rpm])}"/)
            .with_config(%r{/start_test.sh})
        end

        it 'should have a publish job' do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-3publish').with_ensure(:absent)

          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-3-publish')
            .with_config(/<project>/)
            .with_config(%r{<dockerRegistryCredentials>yoloops</dockerRegistryCredentials>})
            .with_config(/project="icinga2"/)
            .with_config(/os="centos"/)
            .with_config(/dist="7"/)
            .with_config(/publish_type="rpm"/)
            .without_config(/^arch=/)
            .with_config(/curl_aptly/)
        end
      end

      context 'with a old control repo' do
        let :title do
          'icinga2-snapshot-centos-7'
        end

        let :params do
          {
            product:         'icinga2',
            pipeline:        'icinga2-snapshot',
            control_repo:    'https://github.com/Icinga/icinga-packaging.git',
            control_rpm:     :undef,
            control_branch:  'snapshot',
            upstream_repo:   'https://github.com/Icinga/icinga2.git',
            upstream_branch: 'support/x.x',
            release_type:    'snapshot'
          }
        end

        it { should compile.with_all_deps }

        # pre_condition
        it { should contain_class('icinga_build::pipeline::defaults') }

        it { should contain_icinga_build__pipeline__rpm('icinga2-snapshot-centos-7') }

        it do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-0source')
            .with_config(/<url>#{Regexp.escape(params[:control_repo])}<.url>/)
            .with_config(%r{<dockerRegistryCredentials/>})
            .with_config(/control_rpm=$/)
            .with_config(/rpmbuild --nodeps -bs/)
            .with_config(/rpmbuild/)
        end

        it do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-1binary')
            .with_config(/matrix-project/)
            .with_config(%r{<dockerRegistryCredentials/>})
            .with_config(/project="icinga2"/)
            .with_config(/rpmbuild --rebuild/)
        end

        it 'should have a test job' do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-2test')
            .with_config(/matrix-project/)
            .with_config(%r{<dockerRegistryCredentials/>})
            .with_config(/project="icinga2"/)
            .with_config(/control_rpm=$/)
            .with_config(%r{/start_test.sh})
        end

        it 'should have a publish job' do
          should contain_jenkins_job('icinga2-snapshot/rpm-centos-7-3-publish')
            .with_config(/curl_aptly/)
            .with_config(%r{<dockerRegistryCredentials/>})
        end
      end
    end
  end
end
