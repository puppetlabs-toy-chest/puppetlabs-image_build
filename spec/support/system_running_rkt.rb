shared_examples 'a system running rkt' do
  ['rkt', 'acbuild'].each do |command|
    describe command("#{command} version") do
      its(:exit_status) { should eq 0 }
    end
  end
end
