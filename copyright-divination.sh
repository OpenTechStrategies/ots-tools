#!/bin/sh

# *~*~*~* ATTENTION: THIS IS A WORK IN PROGRESS THAT IS NOT READY FOR PRODUCTION USE. *~*~*~*
#
# Use this script to find out in which years a given file was modified
# enough to include in copyright notices.  The script takes a
# git-versioned file as its argument and returns a newline-separated
# list of years to include in the copyright notice on that file.
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

#input is a file
FILENAME_PARAM="$1"
TMP_PREFIX=$$
TMP_FILE=$TMP_PREFIX-list-of-years.tmp

# Use "cut" to pull out just the years from this output and save them in another temp file
# write each individual year to the file just once, in order

git log $FILENAME_PARAM | grep -E "Date: " | cut -d " " -f 8 | sort | uniq > $TMP_FILE

# now read the years in the file back through the command line

for y in `cat $TMP_FILE`; do

CURRENT_YEAR=${y}

# find first and last commits in the year

# TODO: need to account for a case with less than three commits in the year
# cases:
# no commits in a year (fine)
# 1 commit in a year
# 2 commits in a year
# 3 or more commits in a year (fine)

END_COMMIT=$(git log --since "$CURRENT_YEAR-01-01" --until "$CURRENT_YEAR-12-31" --pretty=format:"%H" $FILENAME_PARAM | head -1)
echo $CURRENT_YEAR $END_COMMIT
START_COMMIT=$(git log --since "$CURRENT_YEAR-01-01" --until "$CURRENT_YEAR-12-31" --pretty=format:"%H" $FILENAME_PARAM | tail -1)
echo $CURRENT_YEAR $START_COMMIT

YEARLY_DIFF_RESULT_FILE=$TMP_PREFIX-$CURRENT_YEAR-result.tmp

git diff $START_COMMIT..$END_COMMIT > $YEARLY_DIFF_RESULT_FILE

#read file, count lines starting with + and lines starting with -, then find the difference

NUM_LINES_ADDED=$(grep -e "^+ " $YEARLY_DIFF_RESULT_FILE | wc -l)
NUM_LINES_DELETED=$(grep -e "^- " $YEARLY_DIFF_RESULT_FILE | wc -l)

# find abs value of the difference 

YEARLY_DIFF_LINE_COUNT=$(dc -e "$NUM_LINES_ADDED $NUM_LINES_DELETED - 2 ^ v p")

if [ $YEARLY_DIFF_LINE_COUNT -gt 3 ] ; then
    # TODO: write year and filename to our list.
    echo ${y};
fi

done

#output is a list of years in which that file was modified to the tune of 3 total lines or more

# clean up tmp files

rm ${TMP_FILE}
rm ${YEARLY_DIFF_RESULT_FILE}