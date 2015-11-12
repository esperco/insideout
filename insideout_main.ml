open Printf

let split_modules =
  let sep = Str.regexp "[, \t\r\n]+" in
  fun s ->
    Str.split sep s

let main () =
  let out_file = ref None in
  let in_file = ref None in
  let function_name = ref "expand" in
  let mode = ref `Ocaml in
  let escape_function = ref None in
  let rev_opens = ref [] in
  let options = [
    "-f",
    Arg.Set_string function_name,
    "<lowercase identifier>
          Name of the generated OCaml function (default: expand)";

    "-o",
    Arg.String (fun s ->
      if !out_file <> None then
        failwith "Multiple output files"
      else
        out_file := Some s
    ),
    "<file>
          Output file (default: output goes to stdout)";

    "-preview",
    Arg.Unit (fun () -> mode := `Preview),
    "
          Preview mode: substitute variables which have a default value,
          leave others intact.";

    "-xdefaults",
    Arg.Unit (fun () -> mode := `Xdefaults),
    "
          Expand the defaults like in -preview mode but produce a valid
          template, keeping special characters escaped.";

    "-esc",
    Arg.String (fun s ->
      if !escape_function <> None then
        failwith "At most one -esc* option can be specified"
      else
        escape_function := Some s
    ),
    "
          Apply this function on the result of expanding ${} variables
          before injecting them. $${} variables remain unaffected.";

    "-esc-html",
    Arg.Unit (fun () ->
      if !escape_function <> None then
        failwith "At most one -esc* option can be specified"
      else
        escape_function := Some Insideout_emit.escape_html
    ),
    "
          Short for -esc <function that escapes HTML/XML>.";

    "-open",
    Arg.String (fun s ->
      rev_opens := List.rev_append (split_modules s) !rev_opens
    ),
    "Module1,Module2,...
          Comma-separated or space-separated list of module names to open.";
  ]
  in
  let anon_fun s =
    if !in_file <> None then
      failwith "Multiple input files"
    else
      in_file := Some s
  in

  let usage_msg = sprintf "\
Usage: %s [input file] [options]

Convert a template into an OCaml function with labeled arguments.

  Hello ${x}

becomes:

  let gen ~x () = \"Hello \" ^ x

Use a backslash character to escape $ or \\ itself (\\\\\\${x} gives \\${x}).

Also supported are %% format strings (as supported by OCaml's Printf):

  You are user number ${num %%i}.

Finally, default values can be specified after a colon:

  <title>${title:Welcome} to our user number ${ num %%i :1234}!</title>

Command-line options:
"
      Sys.argv.(0)
  in

  Arg.parse options anon_fun usage_msg;

  let custom_esc = !escape_function in

  let ic, source =
    match !in_file with
      None -> stdin, "<stdin>"
    | Some file -> open_in file, file
  in
  let oc =
    match !out_file with
      None -> stdout
    | Some file -> open_out file
  in
  match !mode with
  | `Ocaml ->
      Insideout_emit.ocaml
        ~custom_esc
        ~opens: (List.rev !rev_opens)
        ~expand_function_name: !function_name
        ~source ic oc
  | `Preview ->
      Insideout_emit.preview ~esc:false source ic oc
  | `Xdefaults ->
      Insideout_emit.preview ~esc:true source ic oc

let () = main ()
