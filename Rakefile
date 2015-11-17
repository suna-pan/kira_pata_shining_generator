task :coffee do
  system('coffee --compile --output public/lib coffee/*')
end

task :server do
  system('bundle exec puma -C puma.rb')
end
