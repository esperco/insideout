{
open Printf
open Insideout_ast

let pos1 lexbuf = lexbuf.Lexing.lex_start_p
let pos2 lexbuf = lexbuf.Lexing.lex_curr_p
let loc lexbuf = (pos1 lexbuf, pos2 lexbuf)

let string_of_loc (pos1, pos2) =
  let open Lexing in
  let line1 = pos1.pos_lnum
  and start1 = pos1.pos_bol in
  sprintf "File %S, line %i, characters %i-%i"
    pos1.pos_fname line1
    (pos1.pos_cnum - start1)
    (pos2.pos_cnum - start1)

let error lexbuf msg =
  eprintf "%s:\n%s\n%!" (string_of_loc (loc lexbuf)) msg;
  failwith "Aborted"

let read_file lexbuf fname =
  try
    let ic = open_in fname in
    let len = in_channel_length ic in
    let s = Bytes.create len in
    really_input ic s 0 len;
    Bytes.to_string s
  with e ->
    error lexbuf
      (sprintf "Cannot include file %s: %s" fname (Printexc.to_string e))
}

let blank = [' ' '\t']
let space = [' ' '\t' '\r' '\n']
let ident = ['A'-'Z''a'-'z']['a'-'z' '_' 'A'-'Z' '0'-'9']*
let graph = ['\033'-'\126']
let format_char = graph # ['\\' ':' '}']
let filename = [^'}']+

let dollar_open = '$' ('$'? as double_dollar) '{'

let varname =
  ('.'? as opt_dot)
  ((ident '.')* as path
   ident
   as full_ident)

rule tokens = parse
  | dollar_open space* varname space*
                                   { let esc = double_dollar = "" in
                                     let implicit =
                                       opt_dot = "." || path <> ""
                                     in
                                     let format = opt_format lexbuf in
                                     let default = opt_default lexbuf in
                                     Var {
                                       ident = full_ident;
                                       format;
                                       default;
                                       esc;
                                       implicit;
                                     } :: tokens lexbuf
                                   }
  | dollar_open "@" (filename as filename) "}"
                                   (* as-is inclusion, no substitutions,
                                      no escaping *)
                                   { ignore double_dollar;
                                     let s = read_file lexbuf filename in
                                     Text s :: tokens lexbuf }
  | "\\$"                          { Text "$" :: tokens lexbuf }
  | '\\' '\r'? '\n' blank*         { (* end-of-line backslash and blanks
                                        at the beginning of the next line
                                        are ignored. *)
                                     tokens lexbuf
                                   }
  | "\\\\"                         { Text "\\" :: tokens lexbuf }
  | [^'$''\\']+ as s               { Text s :: tokens lexbuf }
  | _ as c                         { Text (String.make 1 c) :: tokens lexbuf }
  | eof                            { [] }

and opt_format = parse
  | "%" format_char+ as format space*    { Some format }
  | ""                                   { None }

and opt_default = parse
  | ":"    { Some (string [] lexbuf) }
  | "}"    { None }

and string acc = parse
  | "}"                { String.concat "" (List.rev acc) }
  | "\\\\"             { string ("\\" :: acc) lexbuf }
  | "\\}"              { string ("}" :: acc) lexbuf }
  | "\\\n" blank*      { string acc lexbuf }
  | [^'}' '\\']+ as s  { string (s :: acc) lexbuf }
  | _ as c             { string (String.make 1 c :: acc) lexbuf }

{
  open Printf

  let error source msg =
    eprintf "Error in file %s: %s\n%!" source msg;
    exit 1

  let merge_default ~source old_default new_var =
    match old_default, new_var.default with
    | Some a, Some b when a <> b ->
        error source (
          sprintf
            "Variable %s occurs multiple times with a \n\
             different default value."
            new_var.ident
        )
    | None, Some default
    | Some default, None -> Some default

    | old, new_ ->
        assert (old = new_);
        old_default

  let parse_template source ic oc =
    let lexbuf = Lexing.from_channel ic in
    let l = tokens lexbuf in
    let defaults = Hashtbl.create 10 in
    List.iter (
      function
        | Var x ->
            if not x.implicit then
              let id = x.ident in
              (try
                 let old_default = Hashtbl.find defaults id in
                 let default = merge_default ~source old_default x in
                 Hashtbl.replace defaults id default
               with Not_found ->
                 Hashtbl.add defaults id x.default
              )
        | Text _ ->
            ()
    ) l;
    defaults, l

}
