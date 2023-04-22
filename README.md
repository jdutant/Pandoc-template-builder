# Pandoc template builder

[![GitHub build status][CI badge]][CI workflow]

Lua script to build a single Pandoc template file from partials.

[CI badge]: https://img.shields.io/github/actions/workflow/status/jdutant/Pandoc-template-builder/ci.yaml?branch=main
[CI workflow]: https://github.com/jdutant/Pandoc-template-builder/actions/workflows/ci.yaml


## Overview

[Pandoc template files](https://pandoc.org/MANUAL.html#templates) 
may contain [partials](https://pandoc.org/MANUAL.html#partials) 
that call other template files. 

It is sometimes useful to compose a template file from partials but
distribute it as a single file. This script allows you to do this 
by composing a single template file from a source and its partials.
It looks for partial commands such as:

```
$styles.html()$

${ author_block.html() }
```

and imports them into a built template, which can be saved in a file
or printed out to stdout.

* Partial commands must occupy an entire line.
* Partials files and main template file must all have the same extension.
* Partials applied to variables, as in `$variable:partial()$` are not supported.
* The script is recursive: partials within partials are imported.
* As per Pandoc manual, partial files must be in the same folder as the main template file.

## Usage

The script should be run with Pandoc. It takes an input file argument
and an optional output file argument:

```
pandoc lua template-builder -i source.latex -o compiled.latex
```

If no output argument is specified the result is printed to
stdout. 

## License

Copyright 2023 Julien Dutant. MIT License, see LICENSE file for details.

