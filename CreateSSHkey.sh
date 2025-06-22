#!/bin/bash
if [ -z "$3" ]; then
       $3 = ""
if [ -z "$2" ]; then
       $2 = "newkey_rsa"
if [ -z "$1" ]; then
       $1 = $HOME
    
mkdir -p $1/.ssh
ssh-keygen -b 4096 -t rsa -q -f $1/.ssh/$2 -N $3
