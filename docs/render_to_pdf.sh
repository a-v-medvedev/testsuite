#!/bin/bash

DOC=testsuite_XAMG
pandoc --pdf-engine lualatex --include-in-header=nohyphen.cfg --highlight-style=highlight.theme -V geometry:margin=2.4cm ${DOC}.md style.yml -o ${DOC}.pdf
