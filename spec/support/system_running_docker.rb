shared_examples 'a system running docker' do
  describe package('docker-engine') do
    it { is_expected.to be_installed }
  end

  describe service('docker') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end
end
