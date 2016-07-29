notification :off

guard 'rake', :task => 'test' do
  watch(%r{^manifests\/(.+)\.pp$})
  watch(%r{^spec\/(.+)\.rb$})
  watch(%r{^lib\/(.+)\.rb$})
end
