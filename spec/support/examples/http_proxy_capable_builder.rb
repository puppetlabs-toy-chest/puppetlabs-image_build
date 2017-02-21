shared_examples 'a builder capable of utilising an HTTP proxy' do
  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name,
      }
    end
    it 'should not pass a proxy as a build argument' do
      expect(builder.send(:build_command)).not_to include("--build-arg http_proxy=")
    end
  end

  context 'with an HTTP proxy specified' do
    let(:proxy) { 'http://example.com:3142' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        http_proxy: proxy,
      }
    end
    it 'should pass the proxy as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg http_proxy=#{proxy}")
    end
  end
end
