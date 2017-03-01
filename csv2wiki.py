# Parses a CSV and transforms each line into a MediaWiki page.  This is
# a WIP.
#
# This script currently assumes that you are working with a local
# instance of Mediawiki located at 'localhost/mediawiki'.  It would be
# simple to change the main() function to accept a different url via
# user input.
#
# The create_pages script is meant to be run once per CSV/wiki pair.  It
# might have unexpected results if run more than once.  Run the
# delete_pages script in order to run the create script again.
#
# Creating 250 pages takes about 5 minutes using this script.  See the
# TODO about speeding this up.
#
# Usage:
# $ python csv2wiki.py [create | delete] <filename> <username> <password>
#
# NOTE: If you run create/delete multiple times, you may need to run
#
#     $ php maintenance/rebuildall.php
#
# in your mediawiki instance to link pages to their categories properly.
# This script takes about 10 minutes to run for a wiki with <300 pages.
#
#
#
# Copyright (C) 2017 Open Tech Strategies, LLC
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

import csv
from mwclient import Site
from mwclient import errors
import sys


def create_pages(csv_file, site_url, username, password):
    site = Site(('http', site_url), path='/',)
    site.login(username, password)
    
    toc_page = site.pages['List of Proposals']
    toc_text = ""
    categories = []
    
    # read in csv
    with open(csv_file, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        is_header = True
        row_num = 0
        for row in reader:
            if is_header:
                # if this is the first row, save headers
                header_array = []
                for cell in row:
                    header_array.append(cell)
                    is_header = False
            else:
                # Looping over the cells in the row.  Name the sections
                # according to headers.
                cell_num = 0
                for cell in row:
                    if cell_num == 0:
                        # For this new line, generate a mediawiki page
                        title = 'Proposal_'+ str(row_num) + ': ' + cell
                        print("CREATING: " + title)
                        page = site.pages[title]
                        # Add the new page to the list of pages
                        toc_text += '* [[' + title + ']] \n'
                        # Set the contents of each cell to their own section.
                    if cell is not "":
                        # A section can only be created with some text
                        # 
                        if cell_num == (len(row) - 1):
                            # For the last column, create a category (NOTE:
                            # this is overly customized to a certain set of
                            # CSVs; feel free to remove this conditional for
                            # other CSVs)
                            cell_text = '[[Category:' + cell + ']]'
                            
                            # Add this to the list of categories, unless
                            # it's already there:
                            if cell not in categories:
                                categories.append(cell)
                        else:
                            cell_text = cell
                            # TODO: it's probably bad practice to save each page
                            # many times, and it's definitely slowing down the
                            # script.
                        try:
                            page.save(cell_text, section=cell_num, sectiontitle=header_array[cell_num])
                        except errors.APIError:
                            page.save(cell_text, section='new', sectiontitle=header_array[cell_num])
                                
                    cell_num += 1
                
            row_num += 1
        
    # create the TOC page.
    toc_page.save(toc_text)
    
    # generate the category pages
    for category in categories:
        print(category)
        page_title = 'Category:' + category
        page = site.pages[page_title]
        page.save("")

    return

def delete_pages(site_url, username, password):
    site = Site(('http', site_url), path='/',)
    site.login(username, password)
    
    search_result = site.search('Proposal ')
    for result in search_result:
        # get as a page
        print("DELETING: " + result['title'])
        page = site.pages[result['title']]
        # delete with extreme prejudice
        page.delete()

    return

def main():
    error_message = """
        Usage: Please specify 'create' or 'delete'.
        To create pages:
            python csv2wiki.py create <csv_file> <username> <password>
        To delete pages:
            python csv2wiki.py delete <username> <password>
        """
    try:
        if sys.argv[1] == 'create':
            create_pages(sys.argv[2], 'localhost/mediawiki', sys.argv[3], sys.argv[4])
        elif sys.argv[1] == 'delete':
            delete_pages('localhost/mediawiki', sys.argv[2], sys.argv[3])
        else:
            print(error_message)
    except IndexError:
        print(error_message)
    return


main()
