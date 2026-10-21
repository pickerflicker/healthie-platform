require "test_helper"
require_relative "../support/domain_accounts"

class ProviderCredentialsTest < ActiveSupport::TestCase
  include DomainAccounts

  test "credentials default empty and normalize checkbox sentinel duplicates and supported order" do
    provider = create_test_account("provider", "Credential Provider").provider
    assert_equal [], provider.reload.credentials
    provider.update!(credentials: [ "", "LD", "RDN", "RD", "LD", "MD", "CDCES", "CNS" ])
    assert_equal %w[MD RD RDN LD CNS CDCES], provider.reload.credentials
    assert_equal "Credential Provider", provider.user.reload.name
    provider.update!(credentials: [ "" ])
    assert_equal [], provider.reload.credentials
    provider.update!(credentials: [])
    assert_equal [], provider.reload.credentials
  end

  test "the complete catalog persists in supported order through model and database writes" do
    expected = %w[MD DO OD DDS DMD DPM DC RN LPN LVN APRN NP DNP BSN MSN CNM CRNA PA-C RD RDN LD LDN CNS CDCES PhD PsyD LCSW LMFT LPC LMHC LPCC MSW LSW LICSW NCC BCBA PT DPT OTD OTR PTA COTA PharmD RPh AuD CCC-A CCC-SLP ND LAc NBC-HWC]
    assert_equal expected, Provider::CREDENTIALS.keys
    provider = create_test_account("provider", "Complete Catalog Provider").provider
    provider.update!(credentials: expected.reverse + [ "", "PhD", "PA-C" ])
    assert_equal expected, provider.reload.credentials
    Provider.where(id: provider.id).update_all(credentials: expected)
    assert_equal expected, provider.reload.credentials
  end

  test "unsupported and malformed selections cannot save or alter persisted credentials" do
    provider = create_test_account("provider", "Invalid Credential Provider").provider
    provider.update!(credentials: %w[MD])
    [ [ "MD", "FAKE" ], [ "md" ], [ " " ], nil, "MD", { "MD" => "1" }, [ [ "MD" ] ], [ nil ], [ 1 ] ].each do |input|
      assert_not provider.update(credentials: input), "Accepted #{input.inspect}"
      assert provider.errors[:credentials].any?
      assert_equal %w[MD], Provider.find(provider.id).credentials
    end
  end

  test "database rejects unsupported null and null-element arrays bypassing model validation" do
    provider = create_test_account("provider", "Constrained Credential Provider").provider
    [ [ "FAKE" ], [ "" ], [ nil ], nil ].each do |values|
      assert_raises(ActiveRecord::StatementInvalid) do
        Provider.transaction(requires_new: true) do
          Provider.where(id: provider.id).update_all(credentials: values)
        end
      end
    end
    assert_equal [], provider.reload.credentials
  end
end
