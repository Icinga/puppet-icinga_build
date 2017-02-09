require 'spec_helper'

describe 'icinga_build' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      context 'with default parameters' do
        it { should compile.with_all_deps }

        it { should contain_class('icinga_build') }
        it { should contain_class('icinga_build::scripts') }

        it { should contain_class('jenkins') }
        it { should contain_class('jenkins::cli_helper') }

        # for coverage
        it { should contain_user('jenkins') }
        it { should contain_group('jenkins') }
        ['', '/jobs', '/plugins'].each do |p|
          it { should contain_file("/var/lib/jenkins#{p}") }
        end
        it { should contain_jenkins__plugin('credentials') }
        it { should contain_jenkins__sysconfig('AJP_PORT') }
        it { should contain_jenkins__sysconfig('JAVA_ARGS') }
      end
    end
  end
end
