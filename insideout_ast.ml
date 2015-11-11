type var = {
  ident : string;
    (* variable name *)
  format : string option;
    (* e.g. "%d" *)
  default : string option;
    (* default value, for previewing purposes *)
  esc : bool;
    (* whether to escape the expanded string
       with the user-provided function. *)
}

type token =
  | Var of var
  | Text of string
