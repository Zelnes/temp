#!/bin/bash

sed ':a s/\r//g; /=$/{N; s/=\n//; ta}' test-mail | awk -f mail.awk