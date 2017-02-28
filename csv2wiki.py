# Parses a CSV and transforms each line into a MediaWiki page.  This is
# a WIP.
#
# The site name argument should look something like
# "localhost/mediawiki".  We specify 'http' by default because localhost
# doesn't support HTTPS.
#
# Usage:
# $ python csv2wiki.py <filename> <site name> <username> <password>

import csv
from mwclient import Site
from mwclient import errors
import sys

csv_file = sys.argv[1]
site = Site(('http', sys.argv[2]), path='/',)
site.login(sys.argv[3], sys.argv[4])

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
            # for each line, generate a mediawiki page
            page_name = 'Proposal_'+ str(row_num)
            # add the new page to the table of contents
            toc_text += '* [[' + page_name + ']]: '
            print(page_name)
            page = site.pages[page_name]
            
            # Looping over the cells in the row.  Name the sections
            # according to headers.
            cell_num = 0
            for cell in row:
                if cell_num == 0:
                    # Add more information to the title.
                    new_title = 'Proposal_'+ str(row_num) + ': ' + cell
                    try:
                        page.move(new_title)
                    except errors.APIError:
                        # We could delete the existing page, or just
                        # give an error.
                        #old_page = site.pages[new_title]
                        #old_page.delete()
                        #page.move(new_title)
                        print("WARNING: a page named " + new_title + " already exists")
                        
                    toc_text += cell + "\n"
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

