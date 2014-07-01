#!/bin/sh

rsync --recursive --perms --owner --group --times --inplace --delete --stats --human-readable ../ ~/.multipass-bak

