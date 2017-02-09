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
          should contain_jenkins__job(title)
            .with_enabled(true)
            .with_ensure('present')
            .with_config(/<\?xml version/)
            .with_config(/XMLCONTENT/)
            .with_jobname(title)
        end
      end
    end
  end
end