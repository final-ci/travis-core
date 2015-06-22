require 'active_record'
require 'simple_states'
require 'travis/model/encrypted_column'

# Models an incoming request. The only supported source for requests currently is Github.
#
# The Request will be configured by fetching `.travis.yml` from the Github API
# and needs to be approved based on the configuration. Once approved the
# Request creates a Build.
class Request < Travis::Model
  require 'travis/model/request/approval'
  require 'travis/model/request/branches'
  require 'travis/model/request/states'

  include States, SimpleStates

  serialize :token, Travis::Model::EncryptedColumn.new(disable: true)

  class << self
    def last_by_head_commit(head_commit)
      where(head_commit: head_commit).order(:id).last
    end

    def older_than(id)
      recent.where('id < ?', id)
    end

    def recent(limit = 25)
      order('id DESC').limit(limit)
    end
  end

  belongs_to :commit
  belongs_to :repository
  belongs_to :owner, polymorphic: true
  has_many   :builds
  has_many   :events, as: :source

  validates :repository_id, presence: true

  serialize :config
  serialize :payload

  delegate :repository_provider, to: :repository

  def event_type
    read_attribute(:event_type) || 'push'
  end

  def pull_request?
    event_type == 'pull_request'
  end

  def pull_request_title
    if pull_request? && payload
      payload['pull_request'] && payload['pull_request']['title']
    end
  end

  def pull_request_number
    if pull_request? && payload
      payload['pull_request'] && payload['pull_request']['number']
    end
  end

  def branch_name
    if payload && payload['ref']
      payload['ref'].scan(%r{refs/heads/(.*?)$}).flatten.first
    end
  end

  def tag_name
    if payload && payload['ref']
      payload['ref'].scan(%r{refs/tags/(.*?)$}).flatten.first
    end
  end

  def fetch_config_params
    {
      path: '.travis.yml',
      ref: commit.commit,
      repository_name: repository.name,
      project_key: repository.owner_name
    }
  end

  def same_repo_pull_request?
    begin
      payload = Hashr.new(self.payload)
      head_repo = payload.try(:pull_request).try(:head).try(:repo).try(:full_name)
      base_repo = payload.try(:pull_request).try(:base).try(:repo).try(:full_name)
      head_repo && base_repo && head_repo == base_repo
    rescue => e
      Travis.config.error "[request:#{id}] Couldn't determine whether pull request is from the same repository: #{e.message}"
      false
    end
  end

  def creates_jobs?
    Build::Config::Matrix.new(
      Build::Config.new(config).normalize, multi_os: repository.multi_os_enabled?, dist_group_expansion: repository.dist_group_expansion_enabled?
    ).expand.size > 0
  end
end
