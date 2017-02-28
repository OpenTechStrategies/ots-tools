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

toc_page = site.pages['List of Proposals']
toc_text = ""

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
                    toc_text += cell
                # Set the contents of each cell to their own section.
                if cell is not "":
                    # A section can only be created with some text
                    # 
                    # TODO: it's probably bad practice to save each page
                    # many times, and it's definitely slowing down the
                    # script.
                    try:
                        page.save(cell, section=cell_num, sectiontitle=header_array[cell_num])
                    except:
                        page.save(cell, section='new', sectiontitle=header_array[cell_num])
                    
                # TODO: set certain cells as categories instead of sections
                cell_num += 1

        row_num += 1
        
# create the TOC page.
toc_page.save(toc_text)
