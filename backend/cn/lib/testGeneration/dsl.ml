module IT = IndexTerms
open Constraints
open Utils
module CF = Cerb_frontend

type gen =
  | Arbitrary of CF.Ctype.ctype
  | Return of CF.Ctype.ctype * IT.t
  | Filter of Sym.sym * CF.Ctype.ctype * IT.t * gen
  | Map of Sym.sym * CF.Ctype.ctype * IT.t * gen
  | Alloc of CF.Ctype.ctype * Sym.sym
  | Struct of CF.Ctype.ctype * (string * Sym.sym) list

let rec string_of_gen (g : gen) : string =
  match g with
  | Arbitrary ty -> "arbitrary<" ^ string_of_ctype ty ^ ">()"
  | Return (ty, e) -> "return<" ^ string_of_ctype ty ^ ">(" ^ Pp.plain (IT.pp e) ^ ")"
  | Filter (x, ty, e, g') ->
    "filter("
    ^ "|"
    ^ codify_sym x
    ^ ": "
    ^ string_of_ctype ty
    ^ "| "
    ^ Pp.plain (IT.pp e)
    ^ ", "
    ^ string_of_gen g'
    ^ ")"
  | Map (x, ty, e, g') ->
    "map("
    ^ "|"
    ^ codify_sym x
    ^ ": "
    ^ string_of_ctype ty
    ^ "| "
    ^ Pp.plain (IT.pp e)
    ^ ", "
    ^ string_of_gen g'
    ^ ")"
  | Alloc (ty, x) -> "alloc<" ^ string_of_ctype ty ^ ">(" ^ codify_sym x ^ ")"
  | Struct (ty, ms) ->
    "struct<"
    ^ string_of_ctype ty
    ^ ">("
    ^ String.concat ", " (List.map (fun (x, g') -> "." ^ x ^ ": " ^ codify_sym g') ms)
    ^ ")"


type gen_context = (Sym.sym * gen) list

let pp_gen_context (gtx : gen_context) : Pp.document =
  let open Pp in
  group
    (separate_map
       (break 1)
       (fun (x, g) ->
         string "let "
         ^^ string (codify_sym x)
         ^^ string " = "
         ^^ string (string_of_gen g)
         ^^ string ";")
       gtx)


module Optimize = struct
  let optimize (gtx : gen_context) : gen_context = gtx
end

let optimize = Optimize.optimize

module Compile = struct
  let filter_gen (x : Sym.sym) (ty : CF.Ctype.ctype) (cs : constraints) : gen =
    match cs with
    | _ :: _ -> Filter (x, ty, IT.and_ cs (Locations.other __FUNCTION__), Arbitrary ty)
    | [] -> Arbitrary ty


  let compile_gen (x : Sym.sym) (ty : CF.Ctype.ctype) (e : IT.t) (cs : constraints) : gen =
    match e with
    | IT (Sym x', _, _) when sym_codified_equal x x' -> filter_gen x ty cs
    | _ -> Return (ty, e)


  let rec compile_singles'
    (gtx : gen_context)
    (locs : locations)
    (cs : constraints)
    (iter : variables)
    : gen_context * variables
    =
    let get_loc x =
      List.find_map
        (fun (e, y) ->
          if sym_codified_equal x y then (
            match e with IT.IT (Sym z, _, _) -> Some z | _ -> None)
          else
            None)
        locs
    in
    match iter with
    | (x, (ty, e)) :: iter' ->
      let var_in_gtx y =
        List.find_opt (fun (z, _) -> sym_codified_equal y z) gtx |> Option.is_some
      in
      let relevant_cs =
        List.filter
          (fun c ->
            List.exists
              (sym_codified_equal x)
              (c |> IT.free_vars |> IT.SymSet.to_seq |> List.of_seq))
          cs
      in
      let no_free_vars =
        List.for_all
          (fun c ->
            List.for_all
              (fun y -> sym_codified_equal x y || var_in_gtx y)
              (c |> IT.free_vars |> IT.SymSet.to_seq |> List.of_seq))
          relevant_cs
      in
      if no_free_vars then (
        let gen = compile_gen x ty e relevant_cs in
        let gen_loc =
          Alloc (CF.Ctype.Ctype ([], Pointer (CF.Ctype.no_qualifiers, ty)), x)
        in
        match get_loc x with
        | Some x_loc ->
          compile_singles' ((x_loc, gen_loc) :: (x, gen) :: gtx) locs cs iter'
        | None -> compile_singles' ((x, gen) :: gtx) locs cs iter')
      else (
        let gtx, iter' = compile_singles' gtx locs cs iter' in
        (gtx, (x, (ty, e)) :: iter'))
    | [] -> (gtx, iter)


  let rec compile_singles
    (gtx : gen_context)
    (vars : variables)
    (locs : locations)
    (cs : constraints)
    : gen_context
    =
    let gtx, vars = compile_singles' gtx locs cs vars in
    if List.non_empty vars then compile_singles gtx vars locs cs else gtx


  let rec compile_structs'
    (gtx : gen_context)
    (vars : variables)
    (ms : members)
    (locs : locations)
    : gen_context * members
    =
    let get_loc x =
      List.find_map
        (fun (e, y) ->
          if sym_codified_equal x y then (
            match e with IT.IT (Sym z, _, _) -> Some z | _ -> None)
          else
            None)
        locs
    in
    match ms with
    | (x, syms) :: ms' ->
      let gtx, ms' = compile_structs' gtx vars ms' locs in
      let free_vars =
        not
          (List.for_all
             (fun m -> List.assoc_opt sym_codified_equal m.carrier gtx |> Option.is_some)
             syms)
      in
      if free_vars then
        (gtx, (x, syms) :: ms')
      else (
        let _, (ty, _) = List.find (fun (y, _) -> sym_codified_equal x y) vars in
        let mems = List.map (fun m -> (m.name, m.carrier)) syms in
        match get_loc x with
        | Some loc ->
          let gen = Struct (ty, mems) in
          let gen_loc =
            Alloc (CF.Ctype.Ctype ([], Pointer (CF.Ctype.no_qualifiers, ty)), x)
          in
          ((loc, gen_loc) :: (x, gen) :: gtx, ms')
        | None -> ((x, Struct (ty, mems)) :: gtx, ms'))
    | [] -> (gtx, [])


  let rec compile_structs
    (gtx : gen_context)
    (vars : variables)
    (ms : members)
    (locs : locations)
    : gen_context
    =
    let gtx, ms = compile_structs' gtx vars ms locs in
    if List.non_empty ms then compile_structs gtx vars ms locs else gtx


  let compile ((vars, ms, locs, cs) : goal) : gen_context =
    (* Not owned *)
    let vars' =
      List.filter
        (fun (x, _) ->
          List.for_all
            (fun (e, _) ->
              match e with
              | IT.IT (Sym y, _, _) -> not (sym_codified_equal x y)
              | _ -> true)
            locs)
        vars
    in
    (* Not a struct *)
    let vars' =
      List.filter
        (fun (x, _) -> List.for_all (fun (y, _) -> not (sym_codified_equal x y)) ms)
        vars'
    in
    let gtx = compile_singles [] vars' locs cs in
    compile_structs gtx vars ms locs |> List.rev
end

let compile = Compile.compile
