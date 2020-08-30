import os
import re

envtier=os.environ["TF_VAR_envtier"]
TF_VAR_firehawk_path=os.environ["TF_VAR_firehawk_path"]
outdict = {}

template_path = os.environ['tmp_template_path']
# template_path = TF_VAR_firehawk_path + "/tmp/secrets.template"
envtier_mapping_path = TF_VAR_firehawk_path + "/tmp/envtier_mapping.txt"

# set values to those relevant to the current envtier in a dictionary based on the _dev or _prod appended names space on any keys.
extensions = ['_dev', '_prod']
with open(template_path) as f:
    for line in f:
        if line.startswith('#'):
            continue
        
        line = line.split('=')[0]
        for ext in extensions:
            if line.endswith(ext):
                varname = line[:-len(ext)]
                outdict[varname] = varname+'_'+envtier

# write environment mappings to tmp file
with open(envtier_mapping_path, "w") as f:
    for key in outdict:
        print >>f, key+'=$'+outdict[key]