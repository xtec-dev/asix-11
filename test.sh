#!/bin/bash

shopt -s extglob
rm -rf !(test.sh|uf*)
