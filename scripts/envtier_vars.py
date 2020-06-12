import os
import re

envtier=os.environ["TF_VAR_envtier"]
TF_VAR_firehawk_path=os.environ["TF_VAR_firehawk_path"]
outdict = {}

template_path = os.environ['tmp_template_path']
# template_path = TF_VAR_firehawk_path + "/tmp/secrets.template"
envtier_mapping_path = TF_VAR_firehawk_path + "/tmp/envtier_mapping.txt"

# set values to those relevant to the current envtier in a dictionary based on the _dev or _prod appended names space on any keys.
with open(template_path) as f:
    for line in f:
        if not line.startswith('#'):
            if ('_dev' in line) or ('_prod' in line): 
                s = line.split('=')[0]
                s = re.sub('_prod$', '', s)
                s = re.sub('_dev$', '', s)
                varname=s
                outdict[varname] = varname+'_'+envtier

# write environment mappings to tmp file
with open(envtier_mapping_path, "w") as f:
    for key in outdict:
        print >>f, key+'=$'+outdict[key]