header{*Generated by Lem from either.lem.*}

theory "Lem_either" 

imports 
 	 Main
	 "Lem_bool" 
	 "Lem_basic_classes" 
	 "Lem_list" 
	 "Lem_tuple" 

begin 

 

(*open import Bool Basic_classes List Tuple*)
(*open import {hol} `sumTheory`*)
(*open import {ocaml} `Either`*)

(*type either 'a 'b
  = Left  of 'a
  | Right of 'b*)


(* -------------------------------------------------------------------------- *)
(* Equality.                                                                  *)
(* -------------------------------------------------------------------------- *)

(*val eitherEqual : forall 'a 'b. Eq 'a, Eq 'b => (either 'a 'b) -> (either 'a 'b) -> bool*)
(*val eitherEqualBy : forall 'a 'b. ('a -> 'a -> bool) -> ('b -> 'b -> bool) -> (either 'a 'b) -> (either 'a 'b) -> bool*)

definition eitherEqualBy  :: "('a \<Rightarrow> 'a \<Rightarrow> bool)\<Rightarrow>('b \<Rightarrow> 'b \<Rightarrow> bool)\<Rightarrow>('a,'b)sum \<Rightarrow>('a,'b)sum \<Rightarrow> bool "  where 
     " eitherEqualBy eql eqr (left:: ('a, 'b) sum) (right:: ('a, 'b) sum) = (
  (case  (left, right) of
      (Inl l, Inl l') => eql l l'
    | (Inr r, Inr r') => eqr r r'
    | _ => False
  ))"

(*let eitherEqual = eitherEqualBy (=) (=)*)

fun either_setElemCompare  :: "('d \<Rightarrow> 'b \<Rightarrow> ordering)\<Rightarrow>('c \<Rightarrow> 'a \<Rightarrow> ordering)\<Rightarrow>('d,'c)sum \<Rightarrow>('b,'a)sum \<Rightarrow> ordering "  where 
     " either_setElemCompare cmpa cmpb (Inl x') (Inl y') = ( cmpa x' y' )"
|" either_setElemCompare cmpa cmpb (Inr x') (Inr y') = ( cmpb x' y' )"
|" either_setElemCompare cmpa cmpb (Inl _) (Inr _) = ( LT )"
|" either_setElemCompare cmpa cmpb (Inr _) (Inl _) = ( GT )" 
declare either_setElemCompare.simps [simp del]

                           

(* -------------------------------------------------------------------------- *)
(* Utility functions.                                                         *)
(* -------------------------------------------------------------------------- *)

(*val isLeft : forall 'a 'b. either 'a 'b -> bool*)

(*val isRight : forall 'a 'b. either 'a 'b -> bool*)


(*val either : forall 'a 'b 'c. ('a -> 'c) -> ('b -> 'c) -> either 'a 'b -> 'c*)
(*let either fa fb x = match x with
  | Left a -> fa a
  | Right b -> fb b
end*)


(*val partitionEither : forall 'a 'b. list (either 'a 'b) -> (list 'a * list 'b)*)
(*let rec partitionEither l = match l with
  | [] -> ([], [])
  | x :: xs -> begin
      let (ll, rl) = partitionEither xs in
      match x with 
        | Left l -> (l::ll, rl)
        | Right r -> (ll, r::rl)
      end
    end
end*)


(*val lefts : forall 'a 'b. list (either 'a 'b) -> list 'a*)


(*val rights : forall 'a 'b. list (either 'a 'b) -> list 'b*)


end
