require 'spec_helper_acceptance'

describe 'image_build' do
  before(:all) do
    @pp = <<-EOS
      class { 'docker': }
      class { 'rkt':
        version => '1.13.0'
      }
      class { 'rkt::acbuild':
        version => '0.4.0'
      }
    EOS
    apply_manifest_with_exit(@pp)
    scp_to('default', 'spec/fixtures/nginx', '/tmp/nginx/')
    scp_to('default', 'spec/fixtures/invalid', '/tmp/invalid/')
  end

  it 'should have the puppet docker command installed' do
    expect(command('puppet docker --help').exit_status).to eq 0
  end

  it 'should have the puppet aci command installed' do
    expect(command('puppet aci --help').exit_status).to eq 0
  end

  it 'should successfully generate a dockerfile' do
    expect(command('cd /tmp/nginx; puppet docker dockerfile --image-name nginx').exit_status).to eq 0
  end

  it 'should successfully generate a aci build script' do
    expect(command('cd /tmp/nginx; puppet aci script manifests/init.pp --image-name nginx').exit_status).to eq 0
  end

  context 'running a docker build' do
    before(:all) do
      @exit_status = command('cd /tmp/nginx; puppet docker build --image-name nginx').exit_status
    end
    it 'should successfully run docker build' do
      expect(@exit_status).to eq 0
    end
    it 'should result in a base image being pulled' do
      expect(docker_image('ubuntu:16.04')).to exist
    end
    it 'should result in an image being created' do
      expect(docker_image('nginx:latest')).to exist
    end
  end

  context 'running a docker build with an invalid manifest' do
    before(:all) do
      @exit_status = command('cd /tmp/invalid; puppet docker build --image-name invalid').exit_status
    end
    it 'should exit with an error' do
      expect(@exit_status).to eq 1
    end
    it 'should not result in an image being created' do
      expect(docker_image('invalid:latest')).not_to exist
    end
  end

  context 'running a docker build with an alternative image' do
    before(:all) do
      @exit_status = command('cd /tmp/nginx; puppet docker build --image-name nginx-centos --from centos:6 --no-inventory').exit_status
    end
    it 'should successfully run docker build' do
      expect(@exit_status).to eq 0
    end
    it 'should result in a base image being pulled' do
      expect(docker_image('centos:6')).to exist
    end
    it 'should result in an image being created' do
      expect(docker_image('nginx-centos:latest')).to exist
    end
  end

  context 'running an aci build' do
    before(:all) do
      @exit_status = command('cd /tmp/nginx; puppet aci build --image-name nginx').exit_status
    end
    it 'should successfully run acbuild' do
      skip
      expect(@exit_status).to eq 0
    end
    it 'should generate an aci image' do
      skip
      expect(file('/tmp/nginx/nginx.aci')).to exist
    end
  end

  it_behaves_like 'a system running docker'
  it_behaves_like 'a system running rkt'
end
