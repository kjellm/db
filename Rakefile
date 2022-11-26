file "lexer.rb" => "lexer.rex" do |t|
  sh "bundle exec rex -o #{t.name} #{t.prerequisites.join(' ')}"
end

file "parser.rb" => "parser.racc" do |t|
  sh "bundle exec racc -o #{t.name} #{t.prerequisites.join(' ')}"
end

task :default => ["lexer.rb", "parser.rb"]

task :clean do
  rm "lexer.rb, parser.rb"
end

task :test => :default do
  sh "rspec db_spec.rb"
end
