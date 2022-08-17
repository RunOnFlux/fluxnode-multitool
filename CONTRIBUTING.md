# Contributing <br>

## General Information <br>


## Reporting Bugs / Requesting Features <br>
If you found a bug or want to request a feature, please submit it in [issues] <br> 
(https://github.com/RunOnFlux/fluxnode-multitool/issues)<br> <br>
Please submit issues using the gherkin syntax for clear understanding of issue, or at least describe it..
'''Feature: Multiple site support
  Only blog owners can post to a blog, except administrators,
  who can post to all blogs.

  Background:
    Given a global administrator named "Greg"
    And a blog named "Greg's anti-tax rants"
    And a customer named "Dr. Bill"
    And a blog named "Expensive Therapy" owned by "Dr. Bill"

  Scenario: Dr. Bill posts to his own blog
    Given I am logged in as Dr. Bill
    When I try to post to "Expensive Therapy"
    Then I should see "Your article was published."

  Scenario: Dr. Bill tries to post to somebody else's blog, and fails
    Given I am logged in as Dr. Bill
    When I try to post to "Greg's anti-tax rants"
    Then I should see "Hey! That's not your blog!"

  Scenario: Greg posts to a client's blog
    Given I am logged in as Greg
    When I try to post to "Expensive Therapy"
    Then I should see "Your article was published." '''

**If you need help submitting an issue**<br>
please check out this video (https://www.youtube.com/watch?v=TKJ4RdhyB5Y)

## Pull Requests
**Working on your first Pull Request?** <br>
You can learn how from this *free* series [How to Contribute to an Open Source Project on GitHub](https://egghead.io/series/how-to-contribute-to-an-open-source-project-on-github)
