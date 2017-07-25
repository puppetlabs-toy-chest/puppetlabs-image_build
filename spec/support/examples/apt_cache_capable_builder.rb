shared_examples 'a builder capable of utilising an APT cache' do
  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name
      }
    end
    it 'should not pass a proxy as a build argument' do
      expect(builder.send(:build_command)).not_to include('--build-arg APT_PROXY=')
    end
  end

  context 'with an APT proxy specified' do
    let(:proxy) { 'http://example.com:3142' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        apt_proxy: proxy
      }
    end
    it 'should pass the proxy as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg APT_PROXY=#{proxy}")
    end
  end
end
