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

let emit_ocaml use_defaults function_name source oc var_tbl l =
  let vars =
    List.sort
      (fun a b -> String.compare a.ident b.ident)
      (Hashtbl.fold (fun k v acc -> v :: acc) var_tbl [])
  in

  fprintf oc "(* Auto-generated from %s. Do not edit. *)\n" source;
  List.iter (
    fun x ->
      match x.default with
        None -> ()
      | Some s -> fprintf oc "let default_%s = %S\n" x.ident s
  ) vars;

  let args =
    let l =
      List.map (
        function
        | { ident; default = Some default } when use_defaults ->
          sprintf "\n  ?(%s = default_%s)" ident ident
        | { ident } ->
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
  List.iter (
    function
    | Var x ->
      let id = x.ident in
      (match x.format with
       | None ->
         fprintf oc "    %s;\n" id
       | Some fmt ->
         fprintf oc "    Printf.sprintf %S %s;\n" fmt id
      )
    | Text s ->
      fprintf oc "    %S;\n" s
  ) l;
  fprintf oc "  ]\n"

let expand_defaults esc oc l =
  List.iter (
    function
    | Var x ->
      let id = x.ident in
      (match x.default with
         None ->
         let opt_format =
           match x.format with
             None -> ""
           | Some s -> " " ^ s
         in
         fprintf oc "${%s%s}" id opt_format
       | Some s ->
         output_string oc (if esc then escape s else s)
      )
    | Text s ->
      output_string oc (if esc then escape s else s)
  ) l

let ocaml use_defaults function_name source ic oc =
  let var_tbl, l = Insideout_lexer.parse_template source ic oc in
  emit_ocaml use_defaults function_name source oc var_tbl l

let preview esc function_name source ic oc =
  let var_tbl, l = Insideout_lexer.parse_template source ic oc in
  expand_defaults esc oc l
