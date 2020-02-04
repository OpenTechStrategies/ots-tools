# OTS Tools

This repository contains various scripts we wrote at [Open Tech
Strategies](https://opentechstrategies.com) to help us in our work.

The ones we use most often are also the ones most likely to be useful
to others.  They are:

* [oref](emacs-tools/oref.el): a reference management system for Emacs
* [find-dups](find-dups): find duplicate files under a given directory
* [dmgrep](dmgrep): given text organized into delimited blocks, show which blocks match a certain pattern
* [safergrep](safergrep) and [no-longer-than](no-longer-than): helpers for doing `grep`-style pattern-matching
* `ots-org-display-headings-to-point` in [ots.el](emacs-tools/oref.el): an Org Mode helper for figuring out where you are

The other tools may be worth checking out too, of course, depending on
your needs.

Note that once a utility becomes large enough, we usually move it from
here to its own repository.  That's what happened with
[csv2wiki](https://github.com/OpenTechStrategies/csv2wiki) for
example.
