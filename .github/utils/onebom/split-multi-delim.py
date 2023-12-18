import re
import sys

requirement_line = sys.argv[1].strip()
#print f("requirement_line={}", requirement_line)
if not requirement_line.startswith("#") :
    requirement = re.split(r'\s|~|<|>|=', requirement_line)[0]
    if requirement is not None:
        requirement = requirement.replace("_", "-")
        print (requirement)
        sys.exit(0)
sys.exit(-1)
