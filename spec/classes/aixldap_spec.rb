require 'spec_helper'

describe 'aixldap', type: 'class' do
  let(:params) do
    {
      'base_dn'               => 'dc=example,dc=com',
      'bind_dn'               => 'cn=ldapsvc,ou=ServiceAccounts,dc=example,dc=com',
      'bind_password'         => 'NotReallyAPassword',
      'bind_password_crypted' => '{DESv2}253E60C2D1C0D3CFC6C1573651BDA7C77C27FC1E46AFCFB9BEB8AF252ED6F6B4',
      'ldapservers'           => 'ldap01.example.com,ldap02.example.com',
    }
  end

  test_on = {
    :hardwaremodels => [ "/^IBM/"],
    :facterversion  => '3.9',
  }

  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts)do
        facts.merge({
          :aix_local_users => 'one two three',
        })
      end
      it { is_expected.to compile }
    end
  end

  context 'on unsupported OS' do
    let(:facts) do
      {
        :osfamily => 'RedHat',
        :aix_local_users => '',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{AIX}) }
  end
end
