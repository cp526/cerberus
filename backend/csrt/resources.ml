open Pp
module CF = Cerb_frontend
module SymSet = Set.Make(Sym)
module SymMap = Map.Make(Sym)

type size = Z.t



type t = 
  | Uninit of {pointer: IndexTerms.t; size: size}
  | Padding of {pointer: IndexTerms.t; size: size}
  | Points of {pointer: IndexTerms.t; pointee: Sym.t; size: size}
  | Predicate of {pointer: IndexTerms.t; name : Id.t; args: Sym.t list; size : size}

type resource = t

let pp = function
  | Uninit {pointer; size} ->
     !^"Uninit" ^^ parens (IndexTerms.pp pointer ^^ comma ^^ Z.pp size)
  | Padding {pointer; size} ->
     !^"Padding" ^^ parens (IndexTerms.pp pointer ^^ comma ^^ Z.pp size)
  | Points {pointer; pointee; size} ->
     !^"Points" ^^ 
       parens (IndexTerms.pp pointer ^^ comma ^^ Sym.pp pointee ^^ 
                 comma ^^ Z.pp size)
  | Predicate {pointer; name; args; size} ->
     Id.pp name ^^
       parens (IndexTerms.pp pointer) ^^ 
         parens (separate_map (space ^^ comma) Sym.pp args)



let subst_var (subst: (Sym.t,Sym.t) Subst.t) = function
  | Uninit {pointer; size} ->
     let pointer = IndexTerms.subst_var subst pointer in
     Uninit {pointer; size}
  | Padding {pointer; size} ->
     let pointer = IndexTerms.subst_var subst pointer in
     Padding {pointer; size}
  | Points {pointer; pointee; size} -> 
     let pointer = IndexTerms.subst_var subst pointer in
     let pointee = Sym.subst subst pointee in
     Points {pointer; pointee; size}
  | Predicate {pointer; name; args; size} -> 
     let pointer = IndexTerms.subst_var subst pointer in
     let args = List.map (Sym.subst subst) args in
     Predicate {pointer; name; args; size}


let subst_vars = Subst.make_substs subst_var


let equal t1 t2 = 
  match t1, t2 with
  | Uninit u1, Uninit u2 ->
     IndexTerms.equal u1.pointer u2.pointer &&
     Z.equal u1.size u2.size
  | Padding u1, Padding u2 ->
     IndexTerms.equal u1.pointer u2.pointer &&
     Z.equal u1.size u2.size
  | Points p1, Points p2 ->
     IndexTerms.equal p1.pointer p2.pointer &&
     Sym.equal p1.pointee p2.pointee &&
     Z.equal p1.size p2.size
  | Predicate p1, Predicate p2 ->
     IndexTerms.equal p1.pointer p2.pointer && 
     Id.equal p1.name p2.name && 
     List.equal Sym.equal p1.args p2.args &&
     Z.equal p1.size p2.size
  | _, _ -> false


let pointer = function
  | Uninit u -> u.pointer
  | Padding p -> p.pointer
  | Points p -> p.pointer
  | Predicate p -> p.pointer

let size = function
  | Uninit u -> u.size
  | Padding p -> p.size
  | Points p -> p.size
  | Predicate p -> p.size

let fp resource = (pointer resource, size resource)

let vars_in = function
  | Uninit p -> IndexTerms.vars_in p.pointer
  | Padding p -> IndexTerms.vars_in p.pointer
  | Points p -> SymSet.add p.pointee (IndexTerms.vars_in p.pointer)
  | Predicate p -> SymSet.union (IndexTerms.vars_in p.pointer)
                     (SymSet.of_list p.args)


let set_pointer re pointer = 
  match re with
  | Uninit u -> Uninit { u with pointer }
  | Padding p -> Padding { p with pointer }
  | Points p -> Points { p with pointer }
  | Predicate p -> Predicate { p with pointer }


(* requires equality on index terms (does not try to unify them) *)
let unify r1 r2 res = 
  let open Option in
  match r1, r2 with
  | Uninit u, Uninit u' 
       when Z.equal u.size u'.size && IndexTerms.equal u.pointer u'.pointer ->
     return res
  | Padding p, Padding p' 
       when Z.equal p.size p'.size && IndexTerms.equal p.pointer p'.pointer ->
     return res
  | Points p, Points p' 
       when Z.equal p.size p'.size && IndexTerms.equal p.pointer p'.pointer ->
     Uni.unify_sym p.pointee p'.pointee res
  | Predicate p, Predicate p' 
       when Id.equal p.name p'.name && Z.equal p.size p'.size && 
              List.length p.args = List.length p'.args ->
     List.fold_left (fun ores (sym1,sym2) ->
         let* res = ores in
         Uni.unify_sym sym1 sym2 res
       ) (Some res) (List.combine p.args p'.args)
  | _ -> 
     fail


let subst_non_pointer subst = function
  | Uninit u -> Uninit u
  | Padding p -> Padding p
  | Points p -> Points {p with pointee = Sym.subst subst p.pointee}
  | Predicate p -> Predicate {p with args = List.map (Sym.subst subst) p.args}





let input = function
  | Uninit u -> IndexTerms.vars_in u.pointer
  | Padding p -> IndexTerms.vars_in p.pointer
  | Points p -> IndexTerms.vars_in p.pointer
  | Predicate p -> IndexTerms.vars_in p.pointer

let output = function
  | Uninit _ -> SymSet.empty
  | Padding _ -> SymSet.empty
  | Points p -> SymSet.singleton p.pointee
  | Predicate p -> SymSet.of_list p.args



