require 'spec_helper'

# We have to test pupmod::facter::conf via pupmod, because pupmod::facter::conf
# is private.  To take advantage of hooks built into puppet-rspec, the class
# described needs to be the class instantiated, i.e., pupmod. Then, to adjust the
# private class's parameters, we will use hieradata.
describe 'pupmod' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts){ os_facts }

      let(:conf_dir) { '/etc/puppetlabs/facter' }
      let(:conf_file) { '/etc/puppetlabs/facter/facter.conf' }
      let(:params) { { :manage_facter_conf => true }}

      context 'with default facter config (empty sections)' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(conf_dir).with_ensure('directory') }
        it { is_expected.to contain_file(conf_file).with_ensure('file') }
        [ 'facts', 'global', 'cli' ].each do |section|
          it { is_expected.to contain_hocon_setting(section).with(
            :ensure  => 'absent',
            :path    => conf_file,
            :setting => section
          ) }
        end
      end

      context 'with fully specified facter config' do
        let(:hieradata) { 'facter_config' }

        let(:facts_section) { {
          'blocklist' => [ 'EC2' ],
          'ttls'      => [
            { 'processor' => '30 days' },
            { 'timezone'  =>  '8 hours' },
          ]
        } }

        let(:global_section) { {
          'external-dir'     => [ 'path1', 'path2' ],
          'custom-dir'       => [ 'custom/path' ],
          'no-exernal-facts' => false,
          'no-custom-facts'  => false,
          'no-ruby'          => false
        } }

        let(:cli_section) { {
          'debug'     => false,
          'trace'     => true,
          'verbose'   => false,
          'log-level' => 'warn'
        } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(conf_dir).with_ensure('directory') }
        it { is_expected.to contain_file(conf_file).with_ensure('file') }
        it { is_expected.to contain_hocon_setting('facts').with(
          :ensure  => 'present',
          :path    => conf_file,
          :setting => 'facts',
          :value   => facts_section
        ) }
        it { is_expected.to contain_hocon_setting('global').with(
          :ensure  => 'present',
          :path    => conf_file,
          :setting => 'global',
          :value   => global_section
        ) }
        it { is_expected.to contain_hocon_setting('cli').with(
          :ensure  => 'present',
          :path    => conf_file,
          :setting => 'cli',
          :value   => cli_section
        ) }
      end
    end
  end
end
