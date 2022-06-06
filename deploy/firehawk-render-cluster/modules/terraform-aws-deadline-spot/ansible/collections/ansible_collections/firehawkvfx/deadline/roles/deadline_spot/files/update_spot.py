import os, json
from Deadline.Scripting import ClientUtils, RepositoryUtils

# execute with:
# deadlinecommand -ExecuteScriptNoGui "update_spot.py"

def __main__():
    try:
        script_dir = os.path.dirname(os.path.realpath(__file__))
        config_generated = os.path.join(script_dir, 'config_generated.json' )
        with open( config_generated ) as json_file:
            configs = json.load( json_file )
            if not configs:
                raise Exception("No Spot Fleet Request Configuration found.")

            RepositoryUtils.AddOrUpdateServerData("event.plugin.spot", "Config", json.dumps(configs))
    except Exception as e:
        print(e)
        raise e