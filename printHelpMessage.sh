#!/bin/bash

cols=96
screenlog="screenlog.0"

rm -f "$screenlog"
screen -L bash -c "stty cols $cols ; bin/QRGen $* -h"
cat "$screenlog" && rm -f "$screenlog"
