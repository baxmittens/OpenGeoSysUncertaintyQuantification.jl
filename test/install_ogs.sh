# install ogs via pip
# only works with python versions < 3.12 (e.g. 3.11.9)
mkdir ./ogspyvenv
python3 -m venv ./ogspyvenv
source ./ogspyvenv/bin/activate
pip3 install ogs
export OGS_BINARY=./ogspyvenv/bin/ogs