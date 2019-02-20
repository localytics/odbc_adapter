require 'bundler/gem_tasks'

task default: %i[rubocop test]

desc 'Run rubocop'
task :rubocop do
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new do |task|
    task.patterns = ['lib/**/*.rb']
    task.formatters = ['simple']
  end
end

desc 'Run tests'
task :test do
  require 'rake/testtask'

  Rake::TestTask.new do |task|
    task.libs << 'test'
    task.libs << 'lib'
    task.test_files = FileList['test/**/*_test.rb']
  end
end
