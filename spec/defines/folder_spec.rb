require 'spec_helper'

describe 'icinga_build::folder' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end


      context 'with a simple example' do
        let :title do
          'icinga2-debian'
        end

        let :params do
          {
            description: 'Test description with some text'
          }
        end

        it { should compile }

        it { should contain_icinga_build__folder(title) }

        it do
          should contain_jenkins_job(title)
            .with_ensure('present')
            .with_enable(false)
            .with_config(/<\?xml version/)
            .with_config(/<description>#{Regexp.escape(params[:description])}<\/description>/)
            .with_config(/StockFolderIcon/)
            .with_name(title)
        end
      end

      context 'with a complex example' do
        let :title do
          'icinga2-stable'
        end

        let :params do
          {
            description: 'Test description with some text',
            views_xml: 'XMLDATA',
            icon: 'aggregate-status'
          }
        end

        it { should compile }

        it { should contain_icinga_build__folder(title) }

        it do
          should contain_jenkins_job(title)
            .with_ensure('present')
            .with_enable(false)
            .with_name(title)
            .with_config(/<\?xml version/)
            .with_config(/XMLDATA/)
            .with_config(/BallColorFolderIcon/)
        end
      end
    end
  end
end