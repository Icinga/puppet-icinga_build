require 'spec_helper'

describe 'icinga_build::job' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context 'with only basic parameters' do
        let :title do
          'snapshot-jessie-source'
        end

        let :params do
          {
            'template' => 'icinga_build/jobs/blank_template.erb',
            'params'   => {
              'xml_content' => '<!-- XMLCONTENT -->'
            }
          }
        end

        it { should compile }

        it { should contain_icinga_build__job(title) }

        it do
          should contain_jenkins_job(title)
            .with_enable(true)
            .with_name(title)
            .with_ensure('present')
            .with_config(/<\?xml version/)
            .with_config(/XMLCONTENT/)
        end
      end

      context 'with a folder in jobname' do
        let :title do
          'icinga2-debian/snapshot-jessie-source'
        end

        let :pre_condition do
          "
          icinga_build::folder { 'icinga2-debian':
          }
          "
        end

        let :params do
          {
            'template' => 'icinga_build/jobs/blank_template.erb',
            'params'   => {
              'xml_content' => '<!-- XMLCONTENT -->'
            }
          }
        end

        it { should compile.with_all_deps }

        it { should contain_icinga_build__folder('icinga2-debian') }
        it do
          should contain_icinga_build__job('icinga2-debian/snapshot-jessie-source')
            .with_jobname('icinga2-debian/snapshot-jessie-source')
        end
        it do
          should contain_jenkins_job('icinga2-debian/snapshot-jessie-source')
            .with_name('icinga2-debian/snapshot-jessie-source')
        end
      end

      context 'with a folder as parameter' do
        pending
      end
    end
  end
end