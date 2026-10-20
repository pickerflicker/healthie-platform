# Run with: mise exec -- bin/rails runner script/interview_queries.rb
# Read-only; seed the selected development/test database first.
provider = User.find_by!(email: "provider@healthie.example").provider
client = User.find_by!(email: "client@healthie.example").client

queries = {
  "Provider's clients" => provider.clients.order(:id),
  "Client's providers" => client.providers.order(:id),
  "Client's journal entries" => client.journal_entries.order(created_at: :desc, id: :desc),
  "Provider's combined journal feed" => provider.journal_entries.order(created_at: :desc, id: :desc)
}

queries.each do |label, relation|
  puts "\n#{label}"
  puts relation.to_sql
  puts "IDs: #{relation.pluck(:id).inspect}"
  puts relation.explain.inspect
end
