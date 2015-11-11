open Printf
open Insideout_ast

let escape s =
  let buf = Buffer.create (2 * String.length s) in
  for i = 0 to String.length s - 1 do
    match s.[i] with
    | '$' -> Buffer.add_string buf "\\$"
    | '\\' -> Buffer.add_string buf "\\\\"
    | c -> Buffer.add_char buf c
  done;
  Buffer.contents buf

let emit_ocaml ~custom_esc ~defaults ~use_defaults function_name source oc l =
  let vars =
    List.sort
      (fun (a, _) (b, _) -> String.compare a b)
      (Hashtbl.fold (fun k v acc -> (k, v) :: acc) defaults [])
  in

  fprintf oc "(* Auto-generated from %s. Do not edit. *)\n" source;

  (* Call custom escape function (e.g. html_escape) over
     each expanded variable. *)
  let esc =
    match custom_esc with
    | None ->
        (fun s -> s)
    | Some function_source ->
        fprintf oc "let _esc = %s\n;;\n" function_source;
        (fun s -> sprintf "_esc (%s)" s)
  in

  List.iter (fun (ident, opt_default) ->
    match opt_default with
    | None -> ()
    | Some default -> fprintf oc "let default_%s = %S\n" ident default
  ) vars;

  let args =
    let l =
      List.map (fun (ident, opt_default) ->
        match opt_default with
        | Some default when use_defaults ->
            sprintf "\n  ?(%s = default_%s)" ident ident
        | _ ->
            "\n  ~" ^ ident
      ) vars
    in
    String.concat "" l
  in
  fprintf oc "\
let %s%s () =

  String.concat \"\" [\n"
    function_name
    args;
  List.iter (function
    | Var x ->
        let id = x.ident in
        let expanded_var =
          match x.format with
          | None ->
              id
          | Some fmt ->
              sprintf "Printf.sprintf %S %s" fmt id
        in
        fprintf oc "    %s;\n"
          (if x.esc then esc expanded_var else expanded_var)

    | Text s ->
        fprintf oc "    %S;\n" s
  ) l;
  fprintf oc "  ]\n"

let expand_defaults ~defaults ~esc oc l =
  List.iter (function
    | Var x ->
        let id = x.ident in
        (match Hashtbl.find defaults id with
           None ->
             let opt_format =
               match x.format with
                 None -> ""
               | Some s -> " " ^ s
             in
             fprintf oc "$%s{%s%s}" (if x.esc then "" else "$") id opt_format
         | Some s ->
             output_string oc (if esc then escape s else s)
        )
    | Text s ->
        output_string oc (if esc then escape s else s)
  ) l

let ocaml ~custom_esc ~use_defaults function_name source ic oc =
  let defaults, l = Insideout_lexer.parse_template source ic oc in
  emit_ocaml ~custom_esc ~defaults ~use_defaults function_name source oc l

let preview ~esc function_name source ic oc =
  let defaults, l = Insideout_lexer.parse_template source ic oc in
  expand_defaults ~defaults ~esc oc l

let escape_html = "fun s ->
  let buf = Buffer.create (String.length s + 10) in
  String.iter (function
    | '&' -> Buffer.add_string buf \"&amp;\"
    | '<' -> Buffer.add_string buf \"&lt;\"
    | '>' -> Buffer.add_string buf \"&gt;\"
    | '\\'' -> Buffer.add_string buf \"&apos;\"
    | '\"' -> Buffer.add_string buf \"&quot;\"
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.contents buf
"
