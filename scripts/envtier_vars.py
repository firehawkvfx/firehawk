import os
envtier=os.environ["TF_VAR_envtier"]

outdict = {}

# set values to current envtier
with open("./tmp/secrets.template") as f:
    for line in f:
        if not line.startswith('#'):
            if ('_dev' in line) or ('_prod' in line): 
                varname=line.replace('_dev', '').replace('_prod', '').split('=')[0]
                outdict[varname] = varname+'_'+envtier

# write environment mappings to tmp file
with open("./tmp/envtier_mapping.txt", "w") as f:
    for key in outdict:
        print >>f, key+'=$'+outdict[key]