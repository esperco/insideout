insideout
=========

Description
-----------

Convert a template into an OCaml function with labelled arguments.

This is a camlp4-free replacement of the "interpolate file" feature of
[xstrp4](http://projects.camlcity.org/projects/xstrp4.html).

```
Hello ${name}
```

becomes:

```ocaml
let expand ~name () = "Hello " ^ name
```
Use a backslash character to escape $ or \ itself (\\\${x} gives \${x}).

Printf formatting:
```
${x %f}
```
(formats the argument `x` using `Printf.sprintf "%f" x`)

File inclusion (as-is, no escaping, no substitutions):
```
${@foo/bar}
```
(includes the contents of file `foo/bar`)

Default values (useful for previews or suggested usage):
```
${title:Here goes the title}
```

If specified on the command line with `-esc` or `-esc-html`,
text variables injected with `${}` are automatically escaped
using the specified escape function. `$${}` can be used to
inject code without escaping. In the case of HTML,
the command is `insideout -esc-html`.

```html
<h1>${title}</h1>
$${first_section}
```

The generated `expand` function for the example above
can be called as follows:

```ocaml
My_template_html.expand
  ~title: "We <3 html!"
  ~first_section: "<p>It's true that 1 &lt; 2.</p>"
  ()
```

which produces:

```html
<h1>We &lt;3 html!</h1>
<p>It's true that 1 &lt; 2.</p>
```

Use `insideout -help` to see all command-line options.

Installation
------------

(requires a standard OCaml installation)

```
$ make
$ make install
```

Example
-------

See file `example.html` and run demo with:
```
$ make demo
```

TODO
----

* add support for search path for included files
* support inclusion of templates (as opposed to verbatim inclusion
  already supported)
