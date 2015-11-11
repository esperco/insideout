open Printf

let main () =
  let out_file = ref None in
  let in_file = ref None in
  let function_name = ref "gen" in
  let use_defaults = ref true in
  let mode = ref `Ocaml in
  let options = [
    "-f",
    Arg.Set_string function_name,
    "<lowercase identifier>
          Name of the OCaml function (default: gen)";

    "-o",
    Arg.String (
      fun s ->
        if !out_file <> None then
          failwith "Multiple output files"
        else
          out_file := Some s
    ),
    "<file>
          Output file (default: output goes to stdout)";

    "-no-defaults",
    Arg.Clear use_defaults,
    "
          Produce an OCaml function with only required arguments, ignoring
          the defaults found in the template.";

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
    `Ocaml -> Insideout_emit.ocaml !use_defaults !function_name source ic oc
  | `Preview -> Insideout_emit.preview false !function_name source ic oc
  | `Xdefaults -> Insideout_emit.preview true !function_name source ic oc

let () = main ()
