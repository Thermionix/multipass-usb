#!/bin/sh

rsync --recursive --perms --owner --group --times --inplace --delete --stats --human-readable --exclude='.git/' ../ ~/.multipass-bak

