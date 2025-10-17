#!/bin/bash
set -x
. "${HOME}/.venv/bin/activate"
pcbdraw "${@}"
