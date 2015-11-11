type var = {
  ident : string;
  format : string option; (* "%d" *)
  default : string option;
}

type token =
  Var of var
| Text of string
