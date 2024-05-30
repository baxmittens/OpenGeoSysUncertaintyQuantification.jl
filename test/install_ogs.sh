# install ogs via pip
# only works with python versions < 3.12 (e.g. 3.11.9)
mkdir $1/ogspyvenv
python3 -m venv $1/ogspyvenv
source $1/ogspyvenv/bin/activate
pip3 install ogs
# export this temporary; should be added to .profile for persistency
export OGS_BINARY=$1/ogspyvenv/bin/ogs