shared_examples 'a builder capable of utilising an HTTP proxy' do
  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name
      }
    end
    it 'should not pass a proxy as a build argument' do
      expect(builder.send(:build_command)).not_to include('--build-arg http_proxy=')
    end
    it 'should not pass an https proxy as a build argument' do
      expect(builder.send(:build_command)).not_to include('--build-arg https_proxy=')
    end
  end

  context 'with an HTTP and HTTPS proxy specified' do
    let(:http) { 'http://example.com:3142' }
    let(:https) { 'https://example.com:3143' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        http_proxy: http,
        https_proxy: https
      }
    end
    it 'should pass the proxy as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg http_proxy=#{http}")
    end
    it 'should pass the proxy as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg https_proxy=#{https}")
    end
  end
end
