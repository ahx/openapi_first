#!/bin/sh

wrk -t12 -c400 -d10s --latency -s post.lua http://localhost:9292/hello
