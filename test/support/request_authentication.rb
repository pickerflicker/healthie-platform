require_relative "domain_accounts"

module RequestAuthentication
  def log_in_as(user)
    post user_session_path, params: { user: { email: user.email, password: DomainAccounts::PASSWORD } }
  end

  def log_out
    delete destroy_user_session_path
  end
end
