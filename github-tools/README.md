OTS tools for using the GitHub API.
===================================

We are using the PyGithub library.  The following steps should set up
the right environment for running any of these scripts:

    $ git clone https://github.com/PyGithub/PyGithub.git
    $ apt-get install python3-venv  # (may be needed on Debian/Ubuntu)
    $ python3 -m venv env
    $ source env/bin/activate
    $ cd PyGithub
    $ pip3 install .
    $ cd ..
    $ ### run scripts here (e.g., add-labels) ###
    $ deactivate

Some resources used while working on this:

* [Creating a GitHub personal access token for the command line](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
* [PyGithub reference](http://pygithub.readthedocs.io/en/latest/reference.html)
* [Some PyGithub examples](https://chase-seibert.github.io/blog/2016/07/22/pygithub-examples.html) (see [comments on this issue](https://github.com/PyGithub/PyGithub/issues/321) for more)
* [Python3 'venv'](https://docs.python.org/3/library/venv.html)
* [Installing Python packages Using pip and virtualenv](https://packaging.python.org/guides/installing-using-pip-and-virtualenv/)

add-labels
----------

Eventually this script will do something useful.  For now, it just
prints out a list of issue numbers and titles:

    $ ./add-labels --repository "solutionguidance/psm"
    GitHub authorization token ('?' for help): yourtokenblahblahblah
    [...if it's working, see a bunch of issues listed here...]
    $ 


Why we chose the PyGithub library.
----------------------------------

I examined all of the Python GitHub API libraries listed on
https://developer.github.com/v3/libraries/.  The two top contenders
were [PyGithub](https://github.com/PyGithub/PyGithub) and
[github3.py](https://github.com/sigmavirus24/github3.py).  

Of those two, PyGithub seems slightly more convincing as a long-term
investment, having by far the most issues filed and the most pull
requests.  PyGithub had somewhat fewer commits than github3.py (1453
as compared to 2800), but it had more-recent commits.  They have about
the same number of unique committers (if anything, I'd say github3.py
had somewhat better distribution of committers across commits).  

[This StackOverflow
question](https://stackoverflow.com/questions/10625190/most-suitable-python-library-for-github-api-v3)
indicates that PyGithub is a sane choice.  There is widespread
agreement on the Net that PyGithub's documentation is a bit light on
examples, but third parties have stepped in to fill the gap, and the
comments on https://github.com/PyGithub/PyGithub/issues/321 point to
some of them.
