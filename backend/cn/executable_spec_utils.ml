module CF=Cerb_frontend
module A=CF.AilSyntax
module C=CF.Ctype
module Cn=CF.Cn


let mk_expr expr_ = 
  A.AnnotatedExpression ((), [], Location_ocaml.unknown, expr_)

let rm_expr (A.AnnotatedExpression (_, _, _, expr_)) = expr_

let rm_stmt (A.AnnotatedStatement (_, _, stmt_)) = stmt_

let mk_stmt stmt_ = 
  A.AnnotatedStatement (Location_ocaml.unknown, CF.Annot.Attrs [], stmt_)

let mk_ctype ctype_ =
  C.Ctype ([], ctype_)

let empty_qualifiers : C.qualifiers = {const = false; restrict = false; volatile = false}

let empty_attributes = CF.Annot.Attrs []

type cn_dependencies = CF.Symbol.sym list

type cn_dependency_graph = {
  cn_functions_with_dependencies : ( ((CF.Symbol.sym, C.ctype) Cn.cn_function)) list;
  
}

let compute_cn_dependencies ail_prog =
  ail_prog