# Participation and Contribution Guidelines

We welcome questions, suggestions, and contributions.  Please feel
free to file new tickets or [pull
requests](https://help.github.com/articles/about-pull-requests/) here.
You can also chat with us in [OTS Zulip
chat](https://chat.opentechstrategies.com/) -- you'd need to set up an
account there, but that's available to anyone.

Note that submitting issues or pull requests requires a
[GitHub](https://github.com/) account, which anyone can create.

## Commit Messages

Please adhere to [these
guidelines](https://chris.beams.io/posts/git-commit/) for each commit
message.  The "Seven Rules" described in that post are:

1. Separate subject from body with a blank line
2. Limit the subject line to 50 characters
3. Capitalize the subject line
4. Do not end the subject line with a period
5. Use the imperative mood in the subject line
6. Wrap the body at 72 characters
7. Use the body to explain _what_ and _why_ vs. _how_

Think of the commit message as an introduction to the change.  A
reviewer will read the commit message right before reading the diff
itself, so the commit message's purpose is to put the reader in the
right frame of mind to understand the code change.

The reason for the short initial summary line is to support commands,
such as `git show-branch`, that list changes by showing just the first
line of each one's commit message.

If the commit is related to one or more issues, please include the
issue number in the commit message like this: "issue #123".

## Indentation and Whitespace

Please uses spaces, never tabs, and avoid trailing whitespace.  If a
language has a standard indentation amount, use that amount.  E.g.,
indent Python code by 4 spaces per level.

### Expunge Branches Once They Are Merged

Once a branch has been merged to mainline, please delete the branch
(if it is in our repository).  You can do this via the GitHub PR
management interface (it offers a button to delete the branch, once
the PR has been merged), or you can do it from the command line:

    # Make sure you're not on the branch you want to delete.
    $ git branch | grep '^\* '
    * master

    # No output from this == up-to-date, nothing to fetch.
    $ git fetch --dry-run

    # Delete the branch locally, if necessary.
    $ git branch -d some-now-fully-merged-branch

    # Delete it upstream.
    $ git push origin --delete some-now-fully-merged-branch
