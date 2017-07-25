notification :off

scope group: :test

group :test do
  guard 'rake', task: 'test' do
    watch(%r{^manifests\/(.+)\.pp$})
    watch(%r{^spec\/(.+)\.rb$})
    watch(%r{^lib\/(.+)\.rb$})
    watch(%r{^templates\/(.+)\.erb$})
  end
end

group :critic do
  guard 'rake', task: 'rubycritic' do
    watch(%r{^manifests\/(.+)\.pp$})
    watch(%r{^spec\/(.+)\.rb$})
    watch(%r{^lib\/(.+)\.rb$})
    watch(%r{^templates\/(.+)\.erb$})
  end
end
