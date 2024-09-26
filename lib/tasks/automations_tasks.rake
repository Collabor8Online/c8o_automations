namespace :db do
  desc "Rebuild the database"
  task rebuild: %w[db:drop db:create db:migrate db:test:prepare] do
    puts "Database rebuilt"
  end
end
