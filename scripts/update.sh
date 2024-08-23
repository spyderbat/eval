#!/bin/bash

SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
source $SCRIPTPATH/prelude.sh

echo "Uninstalling and reinstalling..."

$SCRIPTPATH/uninstall.sh

$SCRIPTPATH/install.sh

