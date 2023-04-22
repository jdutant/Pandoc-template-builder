# Pandoc template builder

Lua script to build a single Pandoc template file from partials.

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
```

and imports them into a built template, which can be saved in a file
or printed out to stdout.

* The `${...}` syntax, as in `${styles.html()}` isn't supported.
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

