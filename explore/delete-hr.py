import sys
import os
import json

from sumologic import SumoLogic

sumo = SumoLogic(os.environ.get('SUMO_ACCESS_ID'),os.environ.get('SUMO_ACCESS_KEY'))

# backup existing views
views=sumo.get_explorer_views()
with open('hr-existing.json', 'w') as outfile:
    json.dump(views, outfile, indent=4)

print ('Number of arguments:', len(sys.argv), 'arguments.')
print ('Argument List:', str(sys.argv))

explorer_id=sys.argv[1]
sumo.delete_explorer_view(explorer_id)
    