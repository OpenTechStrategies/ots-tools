#!/usr/bin/env python3

# Copyright (C) 2019 Open Tech Strategies, LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""Validate authz file by making sure the paths added in the currend
diff and/or last commit are actual paths that exist in our checkout.
If it finds any errors, it prints those paths.  Otherwise, it exists
silently.

"""

import contextlib
import os
import subprocess
import sys

def slurp(fname):
    with open(fname) as fh:
        return fh.read()
    
@contextlib.contextmanager
def cd(path):
    """Non-robust context manager to change dir    """
    prev_cwd = os.getcwd()
    os.chdir(path)
    yield
    os.chdir(prev_cwd)

def dirs_must_exist(authz_fname, repo_dir):    
        cmd = "svn log --diff -l 1 {}".format(authz_fname)
        svn = subprocess.check_output(cmd, shell=True).decode('UTF-8').split("\n")
        cmd = "svn diff {}".format(authz_fname)
        svn += subprocess.check_output(cmd, shell=True).decode('UTF-8').split("\n")
        missing = []
        for line in [l for l in svn if l.startswith("+[")]:
            token = '+[/trunk/'
            if line.startswith(token):
                path = line[len(token):-1]
                fname = os.path.join(repo_dir, path)
                if not os.path.exists(fname):
                    missing.append(fname)
        if missing:
            sys.stderr.write("Dirs that exist in authz but not in filesystem:\n")
            for fname in missing:
                sys.stderr.write("/trunk{}\n".format(fname[len(repo_dir):]))
                sys.exit(1)

def dirs_must_be_unique(authz_fname, repo_dir):
    """Make sure dirs aren't listed multiple times in the file."""
    adds = []
    dupes = []
    for line in slurp(authz_fname).split("\n"):
        line = line.strip()
        if not line.startswith('['):
            continue
        if line in adds:
            dupes.append(line)
        adds.append(line)
        
    if dupes:
        sys.stderr.write("Directory lines that appear twice:\n")
        for dupe in dupes:
            sys.stderr.write("{}\n".format(dupe))
    sys.exit(1)
    
if __name__ == "__main__":
    try:
        authz_dir, authz_fname = os.path.split(sys.argv[1])
    except IndexError:
        authz_dir = os.path.join(os.environ['OTS_DIR'],
                                 "infra/svn-server/srv/svn/repositories/auth")
        authz_fname = "ots-authz-file"

    try:
        repo_dir = sys.argv[2]
    except IndexError:
        repo_dir = os.environ['OTS_DIR']
        
    with cd(authz_dir):
        dirs_must_exist(authz_fname, repo_dir)
        dirs_must_be_unique(authz_fname, repo_dir)
    sys.exit(0)
