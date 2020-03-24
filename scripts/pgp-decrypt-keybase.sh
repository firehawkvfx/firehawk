#!/bin/bash
echo $1 | base64 --decode | keybase pgp decrypt