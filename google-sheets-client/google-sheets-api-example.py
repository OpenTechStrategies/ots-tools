#!/usr/bin/env python3
#
# Based on https://developers.google.com/sheets/api/quickstart/python
# and https://gist.github.com/burnash/6771295, mashed together into this
# ungodly monster, yea verily I, like Frankenstein, am loath to look
# upon that which I have created.  In other words, I'm not sure I can
# put a copyright or license on this, since it is an extremely
# derivative work.  The Google quickstart script is under Apache 2 (see
# https://github.com/gsuitedevs/python-samples/blob/4acb66239db78090eacd1863afbd060a4438462a/sheets/quickstart/quickstart.py#L16-L45),
# so that's probably the right choice for this script as well.
#
# -------------------------------------------------------------------------
# Copyright (C) 2018 Open Tech Strategies, LLC
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
# -------------------------------------------------------------------------
# 
# Get the dependencies:
#
# pip install --upgrade google-api-python-client
# pip install python-gflags oauth2client
#
# To run this, copy sheets_config.json.tmpl to sheets_config.json and
# make sure that it is updated with the correct values.  Getting those
# values is (may be) a bit of a trial and is described in the links
# above.
#
# Note that you will need to have a Google Account, and that account
# must have access to the spreadsheet whose ID you are using as your
# "sheet_id."
# 
# Run $ python google-sheets-api-example.py

"""
Shows basic usage of the Sheets API. Prints values from a Google Spreadsheet.
"""
from apiclient.discovery import build
from httplib2 import Http
from oauth2client import file, client, tools
import json

# get private information from the config file
config = json.load(open('sheets_config.json'))

# Grant the Sheets API read only access
SCOPES = 'https://www.googleapis.com/auth/spreadsheets.readonly'

creds_store = file.Storage('credentials.json')
creds = creds_store.get()
if not creds or creds.invalid:
    # Interactively prompt for access creds in browser.
    flow = client.OAuth2WebServerFlow(client_id=config['client_id'],
                                      client_secret=config['client_secret'],
                                      scope=SCOPES,
                                      redirect_uri='http://example.com/auth_return')
    creds = tools.run_flow(flow, creds_store)

service = build('sheets', 'v4', http=creds.authorize(Http()))

# Call the Sheets API on the desired spreadsheet
SPREADSHEET_ID = config['sheet_id']
# The range must be given in "A1" notation, which is described in this
# page: https://developers.google.com/sheets/api/guides/concepts
RANGE_NAME = config['range']
result = service.spreadsheets().values().get(spreadsheetId=SPREADSHEET_ID,
                                             range=RANGE_NAME).execute()
values = result.get('values', [])
if not values:
    print('No data found.')
else:
    # Naturally you could do anything here -- we are printing just to
    # verify that we got the right data back.
    for row in values:
        print(row)
