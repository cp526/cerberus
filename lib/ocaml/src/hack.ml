open Global
open Nat_num

open Cabs

(* Part of the escape ANSI's "Select Graphic Rendition" parameters *)
type ansi_style =
  | Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White
  | Bold
  | Underline
  | Blinking
  | Inverted
  (* TODO: the complete list *)

type ansi_format = ansi_style list

let int_fg = function
  | Black     -> 30
  | Red       -> 31
  | Green     -> 32
  | Yellow    -> 33
  | Blue      -> 34
  | Magenta   -> 35
  | Cyan      -> 36
  | White     -> 37
  | Bold      -> 1
  | Underline -> 4
  | Blinking  -> 5
  | Inverted  -> 7


let ansi_format f s =
  let g f = String.concat ";" (List.map (string_of_int -| int_fg) f) ^ "m" in
  "\x1b[" ^ g f ^ s ^ "\x1b[0m" (* TODO: optimize, someday *)


module Print = struct
  module P = Pprint
  
  open P.Operators
  
  
  let pp_integer_suffix s =
    let to_string = function
      | SUFFIX_UNSIGNED           -> "U"
      | SUFFIX_UNSIGNED_LONG      -> "UL"
      | SUFFIX_UNSIGNED_LONG_LONG -> "ULL"
      | SUFFIX_LONG               -> "L"
      | SUFFIX_LONG_LONG          -> "LL"
    in
    P.optional (P.text -| to_string) s
  let pp_integer_constant (i, s) = !^ (string_of_num i) ^^ pp_integer_suffix s
  
  
  let pp_encoding_prefix = function
    | ENCODING_u8 -> !^ "u8"
    | ENCODING_u  -> !^ "u"
    | ENCODING_U  -> !^ "U"
    | ENCODING_L  -> !^ "L"
  let pp_string_literal (enc, s) =
    pp_encoding_prefix enc ^^ (!^ s)
  
  
  let pp_arithop = function
    | MUL  -> P.star
    | DIV  -> P.slash
    | MOD  -> P.percent
    | ADD  -> P.plus
    | SUB  -> P.minus
    | SHL  -> P.langle ^^ P.langle
    | SHR  -> P.rangle ^^ P.rangle
    | BAND -> P.ampersand
    | BOR  -> P.bar
    | XOR  -> P.caret
  
  
  let pp_binop = function
    | ARITHMETIC op -> pp_arithop op
    | COMMA         -> P.comma
    | AND           -> P.ampersand ^^ P.ampersand
    | OR            -> P.bar ^^ P.bar
    | LT            -> P.langle
    | GT            -> P.rangle
    | LE            -> P.langle ^^ P.equals
    | GE            -> P.rangle ^^ P.equals
    | EQ            -> P.equals ^^ P.equals
    | NE            -> P.bang   ^^ P.equals
  
  
  let pp_unop = function
    | POSTFIX_INCR -> P.plus ^^ P.plus
    | POSTFIX_DECR -> P.minus ^^ P.minus
    | PREFIX_INCR  -> P.plus ^^ P.plus
    | PREFIX_DECR  -> P.minus ^^ P.minus
    | ADDRESS      -> P.ampersand
    | INDIRECTION  -> P.star
    | PLUS         -> P.plus
    | MINUS        -> P.minus
    | BNOT         -> P.tilde
    | NOT          -> P.bang
  
  
  let pp_storage_class = function
    | TYPEDEF      -> !^ (ansi_format [Cyan; Bold] "typedef")
    | EXTERN       -> !^ (ansi_format [Cyan; Bold] "extern")
    | STATIC       -> !^ (ansi_format [Cyan; Bold] "static")
    | THREAD_LOCAL -> !^ (ansi_format [Cyan; Bold] "_Thread_Local")
    | AUTO         -> !^ (ansi_format [Cyan; Bold] "auto")
    | REGISTER     -> !^ (ansi_format [Cyan; Bold] "register")
  
  
  let pp_qualifier = function
    | CONST    -> !^ (ansi_format [Cyan; Bold] "const")
    | RESTRICT -> !^ (ansi_format [Cyan; Bold] "restrict")
    | VOLATILE -> !^ (ansi_format [Cyan; Bold] "volatile")
    | ATOMIC   -> !^ (ansi_format [Cyan; Bold] "atomic") (* TODO *)
  
  
  let rec pp_specifier = function
    | VOID     -> !^ (ansi_format [Green] "void")
    | CHAR     -> !^ (ansi_format [Green] "char")
    | SHORT    -> !^ (ansi_format [Green] "short")
    | INT      -> !^ (ansi_format [Green] "int")
    | LONG     -> !^ (ansi_format [Green] "long")
    | SIGNED   -> !^ (ansi_format [Green] "signed")
    | UNSIGNED -> !^ (ansi_format [Green] "unsigned")
    | BOOL     -> !^ (ansi_format [Green] "_Bool")
    | STRUCT (name_opt, decls) ->
        !^ (ansi_format [Green] "struct") ^^
          match decls with
            | []    -> P.empty
            | delcs -> P.lbrace ^^ P.nest 2 (P.break1 ^^
                                               let f ds d = ds ^^ d ^^ P.hardline in
                                               P.sepmap P.break0 pp_struct_union_declaration decls) ^/^ P.rbrace
  
  
  and pp_type = function
    | BASE (qs, ss)     -> pp_qs qs ^^ pp_ss ss
    | ARRAY (qs, ty, e) -> (* pp_qs qs ^^ pp_type ty ^^^ P.brackets (match e with
                                                                       | Some e -> pp_exp e
                                                                       | None   -> P.empty) *)
                           !^ "BOOM"
    | POINTER (qs, ty)  -> pp_qs qs ^^ P.parens (pp_type ty) ^^^ P.star
    | FUNCTION (ty, ds) -> pp_type ty ^^ P.parens (!^ "TODO") (* (P.comma_list f ts) *) (* TODO *)
  
  
  and pp_exp (exp, _) =
    let f = P.group -| P.parens -| pp_exp in
    match exp with
      | IDENTIFIER id                 -> !^ id
(* TODO: incomplete pattern *)
      | CONSTANT (CONST_INT ic)       -> pp_integer_constant ic
      | STRING_LITERAL s              -> P.dquotes (pp_string_literal s)
      | SUBSCRIPT (e1, e2)            -> f e1 ^^ P.brackets (f e2)
      | CALL (e, es)                  -> f e ^^ P.parens (P.comma_list f es)
      | MEMBEROF (e, x)               -> f e ^^ P.dot ^^ (!^ x)
      | MEMBEROFPTR (e,x)             -> f e ^^ (!^ "->") ^^ (!^ x)
      | UNARY (POSTFIX_INCR as op, e) -> f e ^^ pp_unop op
      | UNARY (POSTFIX_DECR as op, e) -> f e ^^ pp_unop op
      | UNARY (op, e)                 -> pp_unop op ^^ f e
      | TYPE_SIZEOF ty                -> !^ "sizeof"  ^^ P.parens (pp_type ty)
      | TYPE_ALIGNOF ty               -> !^ "alignof" ^^ P.parens (pp_type ty)
      | CAST (ty, e)                  -> P.parens (pp_type ty) ^^^ f e
      | BINARY (COMMA as op, e1, e2)  -> f e1 ^^ pp_binop op ^^ P.space ^^ f e2
      | BINARY (op, e1, e2)           -> f e1 ^^^ pp_binop op ^^^ f e2
      | CONDITIONAL (e1, e2, e3)      -> P.group (f e1 ^^^ P.qmark ^/^ f e2 ^^^ P.colon ^/^ f e3)
      | ASSIGN (op_opt, e1, e2)       -> f e1 ^^^ (P.optional pp_arithop op_opt ^^ P.equals) ^^^ f e2
  
  
  and ins_space ds d = ds ^^ d ^^ P.space
  and pp_qs qs =
      P.fold ins_space (List.map pp_qualifier (Pset.elements qs))
  and pp_ss ss =
      let rec replicate x = function
        | 0    -> P.empty
        | n    -> pp_specifier x ^^^ replicate x (n-1) in
      P.fold ins_space (List.map (fun (x,n) -> replicate x n) (Pmap.bindings ss))
  
  
  and pp_struct_union_declarator = function
    | STRUCT_DECL (id, ty) -> !^ (ansi_format [Yellow] id) (* ^^ P.parens (pp_type ty) *)
    | BITFIELD (x_opt, e)  -> P.optional (fun (s,ty) -> !^ (ansi_format [Yellow] s) (* ^^ P.parens (pp_type ty) *)) x_opt ^^^
                              P.colon ^^ pp_exp e
  
  and pp_struct_union_declaration (ss, qs, decls) =
    pp_qs qs ^^ pp_ss ss ^^ P.sepmap (P.comma ^^ P.space) pp_struct_union_declarator decls ^^ P.semi










      


(*
  and pp_id id = !^ (Symbol.to_string_pretty id)

  let pp_decl file id =
    let (t, st) = Pmap.find id file.id_map in
    pp_type t ^^^ pp_id id
*)

  let rec pp_stmt (stmt, _) =
    match stmt with
      | SKIP                                -> P.semi
      | LABEL (id, s)                       -> !^ id ^^ P.colon ^^^ pp_stmt s
      | CASE (e, s)                         -> pp_exp e ^^ P.colon ^^^ pp_stmt s
      | DEFAULT s                           -> !^ "default" ^^ P.colon ^^^ pp_stmt s
      | BLOCK ss                            -> let block = P.sepmap P.break1 pp_stmt ss in
                                               P.lbrace ^^ P.nest 2 (P.break1 ^^ block) ^/^ P.rbrace
      | EXPRESSION e                        -> pp_exp e ^^ P.semi
      | IF (e, s1, Some s2)                 -> !^ (ansi_format [Cyan; Bold] "if") ^^^ P.parens (pp_exp e) ^^^
                                               pp_stmt s1 ^^^ !^ (ansi_format [Cyan; Bold] "else") ^^^
                                               pp_stmt s2
      | IF (e, s1, None)                    -> !^ (ansi_format [Cyan; Bold] "if") ^^^ P.parens (pp_exp e) ^^^
                                               pp_stmt s1
      | SWITCH (e, s)                       -> !^ (ansi_format [Cyan; Bold] "switch") ^^^
                                               P.parens (pp_exp e) ^/^ pp_stmt s
      | WHILE (e, s)                        -> !^ (ansi_format [Cyan; Bold] "while") ^^^
                                               P.parens (pp_exp e) ^/^ pp_stmt s
      | DO (e, s)                           -> !^ (ansi_format [Cyan; Bold] "do") ^/^ pp_stmt s ^/^
                                               !^ (ansi_format [Cyan; Bold] "while") ^^^ P.parens (pp_exp e)
      | FOR_EXP (e1_opt, e2_opt, e3_opt, s) -> !^ (ansi_format [Cyan; Bold] "for") ^^
                                               P.parens (P.optional pp_exp e1_opt ^^ P.semi ^^^
                                                         P.optional pp_exp e2_opt ^^ P.semi ^^^
                                                         P.optional pp_exp e3_opt) ^/^ pp_stmt s
      | FOR_DECL (defs, e1_opt, e2_opt, s)  -> !^ "for" (* TODO *)
      | GOTO id                             -> !^ (ansi_format [Cyan; Bold] "goto") ^^^ !^ id ^^ P.semi
      | CONTINUE                            -> !^ (ansi_format [Cyan; Bold] "continue") ^^ P.semi
      | BREAK                               -> !^ (ansi_format [Cyan; Bold] "break") ^^ P.semi
      | RETURN (Some e)                     -> !^ (ansi_format [Cyan; Bold] "return") ^^^ pp_exp e ^^ P.semi
      | RETURN None                         -> !^ (ansi_format [Cyan; Bold] "return") ^^ P.semi
      | DECLARATION defs                    -> P.comma_list pp_definition defs ^^ P.semi
  
  and pp_declaration ((s, ty, scs), _) =
    P.fold ins_space (List.map pp_storage_class scs) ^^
    (match ty with
      | ARRAY (qs, ty, e) -> pp_qs qs ^^ pp_type ty ^^^ (!^ s) ^^
                             P.brackets (match e with Some e -> pp_exp e | None -> P.empty)
      | FUNCTION (ty, decls) -> pp_type ty ^^ !^ (ansi_format [Blue] s) ^^
                                P.parens (P.sepmap (P.comma ^^ P.space) pp_declaration decls)
      | ty                   -> pp_type ty ^^ !^ (ansi_format [Yellow] s))
    
  
  and pp_definition ((dec, exp_opt), _) =
    pp_declaration dec ^^^
    (match exp_opt with Some exp -> P.equals ^^^ pp_exp exp | None -> P.empty)
  
  let pp_global_definition (def, _) =
    match def with
      | FUNCTION_DEFINITION (decl, stmt) -> pp_declaration decl ^^^ pp_stmt stmt
      | EXTERNAL_DECLARATION (decls)     -> 
Printf.printf "> %d\n" (List.length decls);
                                            P.fold ins_space (List.map pp_definition decls)
                                              
  let pp_file (filename, defs) =
    let pp d def = d ^^ pp_global_definition def ^^ P.break1 in
    List.fold_left pp P.empty defs
end

