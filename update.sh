#!/bin/bash

git pl origin gh-pages && ruby index.rb && git cma "Updating contributions"&& git ps origin gh-pages 