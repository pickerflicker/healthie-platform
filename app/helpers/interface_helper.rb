module InterfaceHelper
  def workspace_home_path
    current_user.provider? ? provider_home_path : client_home_path
  end

  def workspace_links
    if current_user.provider?
      [ [ "Home", provider_home_path, "Provider home" ], [ "Clients", enrollments_path, "Clients" ], [ "Journal feed", journal_entries_path, "Journal feed" ] ]
    else
      [ [ "Home", client_home_path, "Client home" ], [ "Journal", journal_entries_path, "Journal" ], [ "Providers", enrollments_path, "Providers" ] ]
    end
  end

  def workspace_current?(path)
    case path
    when journal_entries_path
      controller_name == "journal_entries"
    when provider_home_path
      controller_name == "providers"
    else
      request.path == path
    end
  end

  def initials(name)
    name.split.first(2).map { |part| part.first }.join.upcase
  end
end
