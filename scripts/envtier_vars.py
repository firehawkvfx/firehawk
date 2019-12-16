import os
envtier=os.environ["TF_VAR_envtier"]
TF_VAR_firehawk_path=os.environ["TF_VAR_firehawk_path"]
outdict = {}

template_path = TF_VAR_firehawk_path + "/tmp/secrets.template"
envtier_mapping_path = TF_VAR_firehawk_path + "/tmp/envtier_mapping.txt"

# set values to those relevant to the current envtier in a dictionary based on the _dev or _prod appended names space on any keys.
with open(template_path) as f:
    for line in f:
        if not line.startswith('#'):
            if ('_dev' in line) or ('_prod' in line): 
                varname=line.replace('_dev', '').replace('_prod', '').split('=')[0]
                outdict[varname] = varname+'_'+envtier

# write environment mappings to tmp file
with open(envtier_mapping_path, "w") as f:
    for key in outdict:
        print >>f, key+'=$'+outdict[key]