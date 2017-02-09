require 'spec_helper'

describe 'icinga_build::scripts' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context 'with default parameters' do
        it { should compile.with_all_deps }

        it { should contain_class('icinga_build::scripts') }

        it { should contain_file('/var/lib/jenkins/jenkins-scripts').with_ensure('directory') }
      end
    end
  end
end
