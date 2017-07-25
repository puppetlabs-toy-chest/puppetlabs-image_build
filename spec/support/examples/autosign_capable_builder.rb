shared_examples 'an autosign capable builder' do
  context 'with minimal arguments' do
    let(:args) do
      {
        from: from,
        image_name: image_name
      }
    end
    it 'should not pass an autosign token build argument' do
      expect(builder.send(:build_command)).not_to include('--build-arg AUTOSIGN_TOKEN=')
    end
  end

  context 'with an autosign token specified' do
    let(:token) { '12345abcde' }
    let(:args) do
      {
        from: from,
        image_name: image_name,
        autosign_token: token
      }
    end
    it 'should pass the token as a build argument' do
      expect(builder.send(:build_command)).to include("--build-arg AUTOSIGN_TOKEN=#{token}")
    end
  end
end
