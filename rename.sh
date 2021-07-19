#!/bin/bash

for name in `ls *`
do
    mv $name ${name%.txt}.cpp
done
