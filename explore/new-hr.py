import sys
import os
import json

from sumologic import SumoLogic

sumo = SumoLogic(os.environ.get('SUMO_ACCESS_ID'),os.environ.get('SUMO_ACCESS_KEY'))

# backup existing views
views=sumo.get_explorer_views()
with open('hr-existing.json', 'w') as outfile:
    json.dump(views, outfile, indent=4)

# load the new explore view
with open('./hr-static.json') as json_file:
    data = json.load(json_file)

# create the explore view
sumo.create_explorer_view(data)

