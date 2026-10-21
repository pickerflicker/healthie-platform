module ApplicationHelper
  def provider_name(name, credentials)
    ([ name ] + Provider::CREDENTIALS.keys.select { |value| credentials.include?(value) }).join(", ")
  end
end
