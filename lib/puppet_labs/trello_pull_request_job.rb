require 'puppet_labs/base_trello_job'
require 'puppet_labs/pull_request'
require 'chronic_duration'

module PuppetLabs
  ##
  # TrelloPullRequestJob is responsible for performing the action of updating a
  # Trello card based on a bunch of Pull Request data.  This data generally
  # comes from a webhook event.
  #
  # Instances of this object are meant to be stored with Delayed Job
class TrelloPullRequestJob < BaseTrelloJob
  attr_accessor :pull_request

  def cla_status(pr)
    # The CLA status of the PR author
    if cla_signed_time = pr.signed_time(pr.author)
      age_num = Time.now - cla_signed_time
      age = ChronicDuration.output(age_num, :units => 2)
      "CLA Status (PR Author): **SIGNED** #{age} ago"
    else
      "CLA Status (PR Author): **NOT SIGNED**"
    end
  rescue PuppetLabs::ClaAPI::ApiError => detail
    "CLA Status (PR Author): **[UNKNOWN](https://cla.puppetlabs.com/admin/users?q=#{pr.author}&commit=Search)**"
  end

  def card_body
    pr = pull_request

    str = [ 'Contributor Information',
            '----',
            '',
            "![#{pr.author_name}](#{pr.author_avatar_url})",
            '',
            " * Author: **#{pr.author_name}** <#{pr.author_email}>"
    ].join("\n") << "\n"

    if pr.cla_enabled?
      str << " * #{cla_status(pr)}\n"
    end

    str << [ " * Company: #{pr.author_company}",
             " * Github ID: [#{pr.author}](#{pr.author_html_url})",
             " * [Pull Request #{pr.number} Discussion](#{pr.html_url})",
             " * [File Diff](#{pr.html_url}/files)",
             '',
             'Pull Request',
             '====',
             pr.body,
    ].join("\n") << "\n"
  end

  def card_identifier
    pr = pull_request
    "(PR #{pr.repo_name}/#{pr.number})"
  end

  def card_title
    pr = pull_request
    "#{card_identifier} #{pr.title} [#{pr.author_name}]"
  end

  def queue_name
    'pull_request'
  end
end

class TrelloPullRequestClosedJob < TrelloPullRequestJob
  def perform
    name = card_title
    display "Processing: #{name}"
    if card = find_card(name)
      display "Found card #{name} id=#{card.short_id}"
      # TODO Obtain the last comment on the pull request and act on it.
      if archive_card?
        card.add_comment "Automatically archiving card, the pull request is closed."
        card.closed = true
      else
        card.add_comment "This pull request is closed."
      end
      card.save
    else
      display "No card named #{name} found."
    end
    true
  end
end

class TrelloPullRequestReopenedJob < TrelloPullRequestJob
  def perform
    display "FIXME cannot perform any actions when a pull request is reopened"
    # Move the card to the target list
    # Set a new due date for the card
  end
end
end
