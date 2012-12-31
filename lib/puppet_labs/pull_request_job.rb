require 'puppet_labs/pull_request'
require 'puppet_labs/sinatra_dj'

module PuppetLabs
  ##
  # PullRequestJob is responsible for performing the action of updating a
  # Trello card based on a bunch of Pull Request data.  This data generally
  # comes from a webhook event.
  #
  # Instances of this object are meant to be stored with Delayed Job
class PullRequestJob
  include PuppetLabs::SinatraDJ
  attr_accessor :pull_request

  def card_body
    pr = pull_request
    str = [ "Links: [Pull Request #{pr.number} Discussion](#{pr.html_url}) and",
            "[File Diff](#{pr.html_url}/files)",
            '',
            pr.body,
    ].join("\n")
  end

  def card_title
    pr = pull_request
    "(PR #{pr.repo_name}/#{pr.number}) #{pr.title}"
  end

  def perform
    display_card("#{card_title}\n\n#{card_body}")
  end

  def display(str="")
    puts str
  end

  def queue(options={:queue => 'pull_request'})
    queue_job(self, options)
  end
end
end