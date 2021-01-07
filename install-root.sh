#!/bin/ksh
set -eu

# # ensure directories for config files exist
# find files/* -type d -exec sh -c \
#     'echo {} | sed "s/^files//" | xargs -I"%" mkdir -p %' \;

# install config files
find files/* -type f ! -name "*:meta.sh" -exec sh -c \
    'echo {} | sed "s/^files//" | xargs -I"%" cat {} > %' \;

# run meta scripts (set file mode, owner, permissions, etc.)
find files/* -type f -name  "*\:meta.sh" -exec sh -c \
    'echo {} | sed "s/^files\(.*\):meta\.sh$/\1/" | xargs -I"%" ./{} %' \;
# TODO: fail if these ^^ fail...

./start.sh
