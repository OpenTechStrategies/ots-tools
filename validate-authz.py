#!/usr/bin/env python3

"""Validate authz file by making sure the paths added in the currend
diff and/or last commit are actual paths that exist in our checkout.
If it finds any errors, it prints those paths.  Otherwise, it exists
silently.

"""

import os
import subprocess
import sys

try:
    authz_dir, authz_fname = os.path.split(sys.argv[1])
except IndexError:
    authz_dir = os.path.join(os.environ['OTSDIR'],
                             "infra/svn-server/srv/svn/repositories/auth")
    authz_fname = "ots-authz-file"

try:
    repo_dir = sys.argv[2]
except IndexError:
    repo_dir = os.environ['OTSDIR']
    
def slurp(fname):
    with open(fname) as fh:
        return fh.read()

import contextlib
@contextlib.contextmanager
def cd(path):
    """Non-robust context manager to change dir    """
    prev_cwd = os.getcwd()
    os.chdir(path)
    yield
    os.chdir(prev_cwd)

with cd(authz_dir):
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
        for fname in missing:
            sys.stderr.write("/trunk{}\n".format(fname[len(repo_dir):]))
