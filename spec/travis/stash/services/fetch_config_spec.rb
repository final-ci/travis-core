require 'spec_helper'

class StashClientFaker
  def initialize(opts)
  end
end

describe Travis::Stash::Services::FetchConfig do
  include Support::Redis
  include Support::ActiveRecord

  let(:body)      { { 'content' => ['foo: Foo'].pack('m') } }
  let(:repo)      { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:request)  { Factory(:request, :repository => repo) }
  let(:service)   { described_class.new(nil, repo.owner, request: request) }
  let(:result)    { service.run }
  let(:exception) { GH::Error.new }

  #before :each do
  #  StashClientFaker.stubs(:content).with(request.fetch_config_params).returns(body)
  #  Travis::Stash.stubs(:authenticated).with(repo.owner).returns(
  #    StashClientFaker.new({}).stubs(:content).returns(body)
  #  )
  #end

  #describe 'config' do
  #  it 'returns a string' do
  #    p result
  #    result.should be_a(String)
  #  end
  #end

end

describe Travis::Stash::Services::FetchConfig::Instrument do
  include Travis::Testing::Stubs

  let(:body)      { { 'content' => ['foo: Foo'].pack('m') } }
  let(:service)   { Travis::Github::Services::FetchConfig.new(nil, request: request) }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events[1] }

  before :each do
    GH.stubs(:[]).returns(body)
    Travis::Notification.publishers.replace([publisher])
  end

  it 'publishes a payload' do
    service.run
    event.should publish_instrumentation_event(
      event: 'travis.github.services.fetch_config.run:completed',
      message: 'Travis::Github::Services::FetchConfig#run:completed https://api.github.com/repos/svenfuchs/minimal/contents/.travis.yml?ref=62aae5f70ceee39123ef',
      #result: { 'foo' => 'Foo', '.result' => 'configured' },
      result: "foo: Foo",
      data: {
        url: 'https://api.github.com/repos/svenfuchs/minimal/contents/.travis.yml?ref=62aae5f70ceee39123ef'
      }
    )
  end

  it 'strips an access_token if present (1)' do
    service.stubs(:config_url).returns('/foo/bar?access_token=123456')
    service.run
    event[:data][:url].should == '/foo/bar?access_token=[secure]'
  end

  it 'strips an access_token if present (2)' do
    service.stubs(:config_url).returns('/foo/bar?ref=abcd&access_token=123456')
    service.run
    event[:data][:url].should == '/foo/bar?ref=abcd&access_token=[secure]'
  end

  it 'strips a secret if present (2)' do
    service.stubs(:config_url).returns('/foo/bar?ref=abcd&client_secret=123456')
    service.run
    event[:data][:url].should == '/foo/bar?ref=abcd&client_secret=[secure]'
  end
end
