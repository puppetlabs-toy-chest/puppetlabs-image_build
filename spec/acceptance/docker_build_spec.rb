require 'spec_helper_acceptance'

describe 'docker_build' do
  before(:all) do
    @pp = <<-EOS
      class { 'docker': }
    EOS
    apply_manifest_with_exit(@pp)
    scp_to('default', 'spec/fixtures/nginx', '/tmp/nginx/')
  end

  it 'should have the puppet docker command installed' do
    expect(command('puppet docker --help').exit_status).to eq 0
  end

  it 'should successfully generate a dockerfile' do
    expect(command('cd /tmp/nginx; puppet docker dockerfile manifests/init.pp').exit_status).to eq 0
  end

  context 'running a build' do
    before(:all) do
      @exit_status = command('cd /tmp/nginx; puppet docker build manifests/init.pp').exit_status
    end
    it 'should successfully run docker build' do
      expect(@exit_status).to eq 0
    end
    it 'should result in an image being created' do
      expect(docker_image('puppet/nginx')).to exist
    end
  end

  it_behaves_like 'a system running docker'
end
