#!/bin/sh

set -e

c3c run pinentry-c3 <<EOF
OPTION ttyname=$(tty)
SETDESC Test Window
SETPROMPT Pin: 
GETPIN
BYE
EOF

# SETDESC this is a long description%0Aover multiple%0Anlines%0Athis is a long description%0Aover multiple%0Anlinespthis is a long description%0Aover multiple%0Anlines
