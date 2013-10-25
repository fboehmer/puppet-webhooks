require 'puppet_labs/jira/event/pull_request'

require 'puppet_labs/jira/client'

class PuppetLabs::Jira::Event::PullRequest::Base
  include PuppetLabs::Jira::Client

  def self.perform(pull_request, project, client = nil)
    obj = new(pull_request, project, client)
    obj.perform
    obj
  end

  def initialize(pull_request, project, client = nil)
    @pull_request = pull_request
    @project      = project
    @client       = client
  end

  attr_accessor :project
  attr_accessor :pull_request

  attr_writer :logger

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  # Search for a Jira issue associated with a pull request.
  #
  # Issues referenced in the title have priority over issues with an ID so that
  # working with existing issues takes priority over creating a new issue. This
  # is mainly significant for commenting on existing Jira issues with a linked
  # Github pull request.
  def issue_for_pull_request
    @jira_issue ||= (issue_by_title || issue_by_id)
  end

  # Look up a Jira issue containing a string unique to this pull_request
  def issue_by_id
    identifier = @pull_request.identifier

    PuppetLabs::Jira::Issue.matching_webhook_id(client, project, identifier)
  end

  # Try to look up a Jira issue based on the first matching Jira issue in the
  # github pull request title.
  #
  # @example
  #   pull_request.title
  #   #=> "[WH-123] pull requests should be linked to existing tickets
  #   event_handler.issue_by_title
  #   #=> #<PuppetLabs::Jira::Issue:0xdeadbeef key='WH-123'>
  #
  def issue_by_title
    pattern = %r[\b#{@project}-(?:\d+)\b]

    key = @pull_request.title.scan(pattern).first

    if key
      ::JIRA::Resource::Issue.find(client, key)
    end
  end
end