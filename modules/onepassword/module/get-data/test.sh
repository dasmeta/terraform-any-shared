#!/bin/bash

export OP_SECRET_KEY=$2
eval $(echo $1 | op account add --address $3 --email $4 --signin)
eval $(echo $1 | op signin)
pass=$(op item get $5 --vault $6 --fields label=$7)
echo -n "{\"pass\":\"$pass\"}"
