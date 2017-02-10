require 'spec_helper'

describe 'icinga_build::pipeline' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let :pre_condition do
        "
          class { 'icinga_build::pipeline::defaults':
            arch          => ['x86_64', 'i386'],
            jenkins_label => 'docker-test',
            docker_image  => 'private-registry:5000/icinga/{os}-{dist}-{arch}',
          }
          "
      end

      context 'with a simple example' do
        let :title do
          'icinga2-snapshot'
        end

        let :params do
          {
            description:    'Test description with some text',
            control_repo:   'https://github.com/Icinga/icinga-packaging.git',
            control_branch: 'snapshot',
            matrix_deb:     {
              'debian-jessie' => {},
              'debian-wheezy' => {}
            }
          }
        end

        it { should compile.with_all_deps }

        it { should contain_icinga_build__pipeline('icinga2-snapshot') }

        # pre_condition
        it { should contain_class('icinga_build::pipeline::defaults') }

        it do
          should contain_icinga_build__folder('icinga2-snapshot')
            .with_description(/Test description/)
            .with_description(/for icinga2/)
            .with_description(/target snapshot/)
            .with_views_xml('')
          should contain_jenkins_job('icinga2-snapshot')
        end

        it do
          should contain_icinga_build__pipeline__deb('icinga2-snapshot-debian-jessie')
            .with_product('icinga2')
            .with_pipeline('icinga2-snapshot')
            .with_control_repo(params[:control_repo])
            .with_control_branch(params[:control_branch])
            .with_jenkins_label('docker-test')
            .with_docker_image('private-registry:5000/icinga/{os}-{dist}-{arch}')

          # for coverage
          should contain_jenkins_job('icinga2-snapshot/deb-debian-jessie-source')
        end

        it do
          should contain_icinga_build__pipeline__deb('icinga2-snapshot-debian-wheezy')

          # for coverage
          should contain_jenkins_job('icinga2-snapshot/deb-debian-wheezy-source')
        end
      end

      context 'with a complex example' do
        let :title do
          'icinga2'
        end

        let :params do
          {
            description:    'Test description with some text',
            control_repo:   'https://github.com/Icinga/icinga-packaging.git',
            control_branch: 'stable',
            product:        'icinga2',
            target:         'release',
            matrix_deb:     {
              'ubuntu-trusty' => {
                'use' => 'ubuntu'
              },
              'ubuntu-xenial' => {
                'use' => 'ubuntu'
              }
            },
            views_hash:     {
              'Deb' => {
                'include_regex'  => '^deb-.*',
                'grouping_rules' => [
                  {
                    'regex' => '^deb-([\w\d_\.]+)-([\w\d_\.]+)-',
                    'name'  => '$1 $2'
                  }
                ]
              },
              'RPM' => {
                'include_regex'  => '^rpm-.*',
                'grouping_rules' => [
                  {
                    'regex' => '^rpm-([\w\d_\.]+)-([\w\d_\.]+)-',
                    'name'  => '$1 $2'
                  }
                ]
              }
            }
          }
        end

        it { should compile.with_all_deps }

        # pre_condition
        it { should contain_class('icinga_build::pipeline::defaults') }

        it { should contain_icinga_build__pipeline('icinga2') }

        it do
          should contain_icinga_build__folder('icinga2')
            .with_description(/Test description/)
            .with_description(/for icinga2/)
            .with_description(/target release/)
            .with_views_xml(/CategorizedJobsView/)
            .with_views_xml(%r{<name>Deb</name>})
            .with_views_xml(%r{<includeRegex>\^deb-.*</includeRegex>})
            .with_views_xml(%r{<namingRule>\$1 \$2</namingRule>})
            .with_views_xml(%r{<name>RPM</name>})
            .with_views_xml(%r{<includeRegex>\^rpm-.*</includeRegex>})
          should contain_jenkins_job('icinga2')
        end

        it do
          should contain_icinga_build__pipeline__deb('icinga2-ubuntu-xenial')
            .with_product('icinga2')
            .with_pipeline('icinga2')
            .with_use('ubuntu')
            .with_control_repo(params[:control_repo])
            .with_control_branch(params[:control_branch])
            .with_jenkins_label('docker-test')
            .with_docker_image('private-registry:5000/icinga/{os}-{dist}-{arch}')

          # for coverage
          should contain_jenkins_job('icinga2/deb-ubuntu-xenial-source')
        end

        it do
          should contain_icinga_build__pipeline__deb('icinga2-ubuntu-trusty')

          # for coverage
          should contain_jenkins_job('icinga2/deb-ubuntu-trusty-source')
        end
      end
    end
  end
end
