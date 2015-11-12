type var = {
  ident : string;
    (* variable name (x), or path (A.p.x) if implicit *)
  format : string option;
    (* e.g. "%d" *)
  default : string option;
    (* default value, for previewing purposes *)
  esc : bool;
    (* whether to escape the expanded string
       with the user-provided function. *)
  implicit : bool;
    (* whether the variable is taken from the environment (true)
       or is a function parameter (false). *)
}

type token =
  | Var of var
  | Text of string
