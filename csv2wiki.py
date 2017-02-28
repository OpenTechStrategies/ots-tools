# Parses a CSV and transforms each line into a MediaWiki page.  This is
# a WIP.
#
# Usage:
# $ python csv2wiki.py <filename> <site> <username> <password>

import csv
from mwclient import Site
import sys

csv_file = sys.argv[1]
site = Site(('http', sys.argv[2]), path='/',)
site.login(sys.argv[3], sys.argv[4])

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
            page_name = 'Proposal-'+ str(row_num)
            print(page_name)
            page = site.pages[page_name]
            
            # Looping over the cells in the row.  Name the sections
            # according to headers.
            cell_num = 0
            for cell in row:
                # Set the contents of each cell to their own section.
                # TODO: set section title to the header.
                if cell is not "":
                    # A section can only be created with some text
                    # 
                    # TODO: This will keep extending the page as many
                    # times as the script is run.  Setting the section
                    # name (instead of using 'new') should fix this.
                    #
                    # TODO: it's probably bad practice to save each page
                    # many times, and it's definitely slowing down the
                    # script.
                    page.save(cell, section='new')
                    
                # TODO: set certain cells as categories instead of sections
                cell_num += 1

        row_num += 1
