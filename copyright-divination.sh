#!/bin/sh

# This script is still beta software.  We welcome bug reports.
#
# Find out in which years a given file was modified enough to include
# in copyright notices.  The script takes a path to a git-versioned
# file as its argument and returns a newline-separated list of years
# to include in the copyright notice on that file.
# 
# THIS SCRIPT DOES NOT PROVIDE LEGAL ADVICE.  We do not assert that
# its results are correct or that they will stand up under legal
# scrutiny.  The script may return years that are not significant from
# a copyright perspective (false positives).  We are aware of this bug
# but have not introduced heuristics to correct it.  This script is
# designed to assist humans as they determine the correct years to
# include in their copyright notices, not to replace human effort and
# intelligence.
# 
# Usage example.  The <file> here is under git version control and was
# modified in 2005, 2008, and 2011.
#     $ ./copyright-divination.sh <file>
#     2005
#     2008
#     2011
#     $
#

# Copyright (C) 2015 Open Tech Strategies, LLC
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

# input is a file

# send error if argument not given
if [ ${1}X = "X" ]; then
    echo "Error: Argument required. Please enter a filename."
    exit 1
# or if more than one file given
elif [ ${2}X != "X" ]; then
    echo "Error: Please enter only one filename."
    exit 1
else
    FILENAME_PARAM="$1"
fi

TMP_PREFIX=$$
TMP_FILE=$TMP_PREFIX-list-of-years.tmp

# Use "cut" to pull out just the years from this output and save them in another temp file
# write each individual year to the file just once, in order

git log $FILENAME_PARAM | grep -E "Date: " | cut -d " " -f 8 | sort | uniq > $TMP_FILE

# now read the years in the file back through the command line

for y in `cat $TMP_FILE`; do

CURRENT_YEAR=${y}

# find first and last commits in the year

# note that a manual look at git log may show some commits in a year
# that do not turn up using git log --since --until.  These commits
# were probably made in a given year x and pulled into master in
# another year y.  For this script they are changes in year y, even
# though the commit was made in year x.

# NB that this is a complex question and let us reiterate that this
# script does not provide legal advice.

END_COMMIT=$(git log --since "$CURRENT_YEAR-01-01" \
 --until "$CURRENT_YEAR-12-31" --pretty=format:"%H" $FILENAME_PARAM | head -1)
START_COMMIT=$(git log --since "$CURRENT_YEAR-01-01" \
 --until "$CURRENT_YEAR-12-31" --pretty=format:"%H" $FILENAME_PARAM | tail -1)

YEARLY_DIFF_RESULT_FILE=$TMP_PREFIX-$CURRENT_YEAR-result.tmp

# trap the "fatal: Not a valid object name" error from git cat-file
TEST_GIT_COMMIT_RESULT_FILE=$TMP_PREFIX-git-result.tmp
COMMIT_PARENT=$(git cat-file -t "$START_COMMIT^") 2> \
    $TEST_GIT_COMMIT_RESULT_FILE

# if the start and end commits exist and neither is the empty string
if [ "x$START_COMMIT" != "x" -a "x$END_COMMIT" != "x" ]; then
    if [ "$COMMIT_PARENT" = "commit" ]; then #parent commit exists
    # if there is only one commit in the year
        if [ $START_COMMIT = $END_COMMIT ]; then # and start commit parent exists
            git diff-tree "$START_COMMIT^"..$START_COMMIT --stat $FILENAME_PARAM > \
                $YEARLY_DIFF_RESULT_FILE
    # if there are two or more commits in the year
        else
            git diff-tree "$START_COMMIT^"..$END_COMMIT --stat $FILENAME_PARAM > $YEARLY_DIFF_RESULT_FILE
        fi
    else #parent commit does not exist
        git diff-tree $END_COMMIT --root --stat $FILENAME_PARAM > \
            $YEARLY_DIFF_RESULT_FILE
    fi

# read file, find insertions and deletions listed by diff-tree --stat

    NUM_LINES_ADDED=$( awk '{ if ($5 == "insertions(+),") print $4; \
        else if ($5 == "insertions(+)") print $4; }' \
        $YEARLY_DIFF_RESULT_FILE) 
    # convert empty string to zero for dc
    if [ "x$NUM_LINES_ADDED" = "x" ]; then
        NUM_LINES_ADDED=0
    fi
    NUM_LINES_DELETED=$( awk '{ if ($5 == "deletions(-)") print $4; \
        else if ($7 == "deletions(-)") print $6 }' \
        $YEARLY_DIFF_RESULT_FILE) 
    # convert empty string to zero for dc
    if [ "x$NUM_LINES_DELETED" = "x" ]; then
        NUM_LINES_DELETED=0
    fi

# find abs value of the difference 
    YEARLY_DIFF_LINE_COUNT=$(dc -e "$NUM_LINES_ADDED $NUM_LINES_DELETED - 2 ^ v p")
    if [ $YEARLY_DIFF_LINE_COUNT -gt 3 ] ; then
    # TODO: write year and filename to a copyright notice in the file
    # for now, print to stdout
        echo ${y};
    fi

    # clean up tmp file
    rm ${YEARLY_DIFF_RESULT_FILE}

# end if start/end commits exist
fi
# end loop of years modified
done

rm ${TMP_FILE}
rm ${TEST_GIT_COMMIT_RESULT_FILE}

# output is a list of years in which the given file was modified to
# the tune of 3 total lines or more 
