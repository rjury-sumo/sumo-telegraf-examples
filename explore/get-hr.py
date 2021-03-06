import sys
import os
import json

# https://github.com/SumoLogic/sumologic-python-sdk
from sumologic import SumoLogic

sumo = SumoLogic(os.environ.get('SUMO_ACCESS_ID'),os.environ.get('SUMO_ACCESS_KEY'))
views=sumo.get_explorer_views()

print (json.dumps(views, indent=4))
