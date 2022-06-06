import argparse
import sys
import fileinput

if sys.version_info[0] < 3:
    print('You need to run this with Python 3')
    sys.exit(1)

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('strings', metavar='S', type=str, nargs=2,
                    help='The key ( eg: my_key= ) and value ( eg: somevalue ) to replace any existing value with.')
parser.add_argument("-f", "--file", type=str,
                    help="Set file to search and replace")

args = parser.parse_args()
filename=args.file

starts_with = args.strings[0]
append = args.strings[1]

print( "\nFind line that starts with: {}".format( starts_with ) )
print( "Change to: {}{}".format( starts_with, append ) )

updated=False

with fileinput.input(files=(filename), inplace=1) as f:
  for line in f:
    if line.strip().startswith(starts_with):
        line = '{}{}\n'.format( starts_with, append )
        updated=True
    sys.stdout.write(line)

if updated:
    print( "Updated key/value: {}{} in {}".format( starts_with, append, filename ) )
else:
    raise Exception( "ERROR: did not update key/value: {}{} in {}".format( starts_with, append, filename ) )
