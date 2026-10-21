namespace :css do
  desc "Compile Tailwind and daisyUI for Propshaft"
  task :build do
    sh "npm run build:css" unless ENV["HEALTHIE_CSS_PREBUILT"] == "1"
  end
end
Rake::Task["assets:precompile"].enhance([ "css:build" ])
