abort "Seeds are only for local development/test" unless Rails.env.development? || Rails.env.test?

User.transaction do
  [ [ "provider", "Morgan Patel" ], [ "client", "Alex Rivera" ] ].each do |role, name|
    email = "#{role}@healthie.example"
    user = User.find_by(email: email)
    if user
      raise "Seed role mismatch for #{email}" unless user.role == role
      user.update!(name: name, password: "Healthie-demo-2026")
    else
      User.create_account!(name: name, email: email, password: "Healthie-demo-2026", role: role)
    end
  end
end
