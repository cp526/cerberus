(* Generated by Lem from frontend/model/ctype.lem. *)

From Coq Require Import Arith Bool List String.
Require Import Coq.Numbers.BinNums.
Require Import Coq.ZArith.Zcompare.

Require Import ExtLib.Structures.Monad.
Require Import ExtLib.Structures.MonadExc.

From Common Require Import Utils SimpleError.

Require Import CoqLocation.
Require Import CoqSymbol.
Require Import CoqAnnot.

Import MonadNotation.

Open Scope monad_scope.
Open Scope nat_scope.
Open Scope string_scope.

Inductive integerBaseType : Type :=
 | Ichar: integerBaseType
 | Short: integerBaseType
 | Int_: integerBaseType
 | Long: integerBaseType
 | LongLong: integerBaseType
   (* Things defined in the standard libraries *)
 | IntN_t:  nat  -> integerBaseType
 | Int_leastN_t:  nat  -> integerBaseType
 | Int_fastN_t:  nat  -> integerBaseType
 | Intmax_t: integerBaseType
 | Intptr_t: integerBaseType.

(* STD Â§6.2.5#17, sentence 1 *)
Inductive integerType : Type := (* [name = "^\\(\\|\\([a-z A-Z]+_\\)\\)ity[0-9]*'?$"] *)
 | Char: integerType
 | Bool: integerType
 | Signed:  integerBaseType  -> integerType
 | Unsigned:  integerBaseType  -> integerType
 | Enum:  sym  -> integerType
   (* Things defined in the standard libraries *)
 | Wchar_t: integerType
 | Wint_t: integerType
 | Size_t: integerType
 | Ptrdiff_t: integerType
 | Ptraddr_t: integerType .

(* STD Â§6.2.5#10, sentence 1 *)
Inductive realFloatingType : Type :=
| Float: realFloatingType
| Double: realFloatingType
| LongDouble: realFloatingType .

Definition realFloatingType_eqb (a b:realFloatingType): bool
  := match (a,b) with
     | (Float,Float) => true
     | (Double,Double) => true
     | (LongDouble,LongDouble) => true
     | (_,_) => false
     end.

Definition realFloatingType_default: realFloatingType  := Float.

(* STD Â§6.2.5#11, sentence 2 *)
Inductive floatingType : Type :=
  | RealFloating:  realFloatingType  -> floatingType .
Definition floatingType_default: floatingType  := RealFloating realFloatingType_default.
(*  | Complex of floatingType (* STD Â§6.2.5#11, sentence 1 *) *)

Definition floatingType_eqb (a b:floatingType): bool
  := match a, b with
     | RealFloating Float, RealFloating Float => true
     | RealFloating Double, RealFloating Double => true
     | RealFloating LongDouble, RealFloating LongDouble => true
     | _, _ => false
     end.


(* STD Â§6.2.5#14, sentence 1 *)
Inductive basicType : Type :=
 | Integer:  integerType  -> basicType
 | Floating:  floatingType  -> basicType .

(* STD Â§6.2.5#26, sentence 1-2 *)
Record qualifiers : Type (*[name = "^\\(\\|\\([a-z A-Z]+_\\)\\)qs[0-9]*'?$"]*) := {
  const    : bool ;
  restrict : bool ;
  volatile : bool
  (* NOTE: the desugaring collapse _Atomic qualifiers and specifiers *)
  }.

Notation "{[ r 'with' 'const' := e ]}" := ({| const := e; restrict := restrict r; volatile := volatile r |}).
Notation "{[ r 'with' 'restrict' := e ]}" := ({| restrict := e; const := const r; volatile := volatile r |}).
Notation "{[ r 'with' 'volatile' := e ]}" := ({| volatile := e; const := const r; restrict := restrict r |}).

Inductive ctype' : Type := (*[name = "^\\([a-z A-Z]*_\\)?ty[0-9]*'?$"]*)
  | Void: ctype'
  | Basic:  basicType  -> ctype'
    (* INVARIANT if the element ctype is an array, the qualifiers must be empty *)
    (* the qualifiers are that of the element type (Â§6.7.3#9) *)
    (* STD Â§6.2.5#20, bullet 1 *)
  | Array:  ctype  ->  (option  Z  ) -> ctype'
    (* NOTE: the qualifiers associated to a ctype in the
              list of parameters is that of the parameter lvalue. For example if
              we have a parameter with type "restrict pointer to a const char",
              the qualifiers in the tuple will be:
                {no_qualifiers with restrict=true} *)
    (* STD Â§6.2.5#20, bullet 4 *)
  | Function:  ((qualifiers  * ctype ) % type)
              ->  list  ((qualifiers  * ctype  * (* is_register *)bool ) % type)
              ->  (* is_variadic *)bool  -> ctype'
    (* this version only exists during desugaring (for function declarations) *)
    (* TODO: the previous comment is wrong *)
  | FunctionNoParams:  ((qualifiers  * ctype ) % type) -> ctype'  (* function type with no `prototype' *)

    (* STD Â§6.2.5#20, bullet 5 *)
    (* NOTE: the qualifiers are that of the referenced type *)
  | Pointer:  qualifiers  ->  ctype  -> ctype'
    (* STD Â§6.2.5#20, bullet 6 *)
  | Atomic:  ctype  -> ctype'
  | Struct:  sym  -> ctype'
  | Union:  sym  -> ctype'
with ctype : Type :=
  Ctype:  list  CoqAnnot.annot  ->  ctype'  -> ctype .


Definition struct_tag : Type :=  sym.
Definition union_tag : Type :=   sym .
Definition member_id : Type :=   sym .

Inductive flexible_array_member : Type :=
    (* NOTE: the last parameter is the element type of the array *)
  | FlexibleArrayMember:  CoqAnnot.attributes  ->  CoqSymbol.identifier  ->  qualifiers  ->  ctype  -> flexible_array_member .

Inductive alignment : Type :=
  | AlignInteger: Z -> alignment
  | AlignType: ctype -> alignment .

Inductive tag_definition : Type :=
  | StructDef:  list  ((CoqSymbol.identifier  * ((CoqAnnot.attributes  * option alignment * qualifiers  * ctype ) % type)) % type) ->  option  flexible_array_member   -> tag_definition
  | UnionDef:  list  ((CoqSymbol.identifier  * ((CoqAnnot.attributes  * option alignment * qualifiers  * ctype ) % type)) % type) -> tag_definition .

(** Type class instances *)

Definition integerBaseTypeEqual  (ibty1 : integerBaseType ) (ibty2 : integerBaseType )  : bool :=
  let ord := fun (x : integerBaseType ) =>
   match (x) with | Ichar => ( 0%nat : nat ) | Short =>  1%nat | Int_ =>
      2%nat | Long =>  3%nat | LongLong =>  4%nat | IntN_t _ =>  5%nat
     | Int_leastN_t _ =>  6%nat | Int_fastN_t _ =>  7%nat | Intmax_t =>
      8%nat | Intptr_t =>  9%nat end in
  match ( (ibty1, ibty2)) with
    | (IntN_t n1,  IntN_t n2) => Nat.eqb
        n1 n2
    | (Int_leastN_t n1,  Int_leastN_t n2) => Nat.eqb
        n1 n2
    | (Int_fastN_t n1,  Int_fastN_t n2) => Nat.eqb
        n1 n2
    | _ => Nat.eqb
        (ord ibty1) (ord ibty2)
  end.

Definition integerTypeEqual  (ity1: integerType ) (ity2: integerType )  : bool
  :=
  let ord (x : integerType ) :=
    match (x) with
    | Char => ( 0%nat : nat )
    | Bool =>  1%nat
    | Signed _ => 2%nat
    | Unsigned _ =>  3%nat
    | Enum _ =>  4%nat
    | Size_t =>  5%nat
    | Wchar_t =>  6%nat
    | Wint_t =>  7%nat
    | Ptrdiff_t =>  8%nat
    | Ptraddr_t =>  9%nat
    end
  in
  match ((ity1, ity2)) with
  | (Signed ibty1,  Signed ibty2) => integerBaseTypeEqual ibty1 ibty2
  | (Unsigned ibty1,  Unsigned ibty2) => integerBaseTypeEqual  ibty1 ibty2
  | (Enum sym1,  Enum sym2) =>
      match ((sym1, sym2)) with
      | (Symbol d1 n1 sd1,  Symbol d2 n2 sd2) =>
          Z.eqb
            (digest_compare d1 d2)
            ((Z.pred (Z.pos (P_of_succ_nat 0%nat)))) && Z.eqb n1 n2
      end
  | _ => Nat.eqb (ord ity1) (ord ity2)
  end.

(*

Instance x37_Eq : Eq integerType := {
   isEqual   :=  integerTypeEqual;
   isInequal  :=  fun  ity1  ity2 => negb (integerTypeEqual ity1 ity2)
}.


Instance x36_Eq : Eq realFloatingType := {
   isEqual   :=  classical_boolean_equivalence;
   isInequal  :=  unsafe_structural_inequality
}.


Instance x35_Eq : Eq floatingType := {
   isEqual   :=  classical_boolean_equivalence;
   isInequal  :=  unsafe_structural_inequality
}.

*)

(* STD Â§6.2.5#14, sentence 3 *)
Definition basicTypeEqual  (bty1 : basicType ) (bty2 : basicType )  : bool :=
  let ord := fun (x : basicType ) =>
               match (x) with | Integer _ => ( 0%nat : nat ) | Floating _ =>  1%nat end in
  match ( (bty1, bty2)) with
  | (Integer ity1, Integer ity2) =>
      integerTypeEqual ity1 ity2
  | (Floating fty1,  Floating fty2) =>
      floatingType_eqb fty1 fty2
  | _ => Nat.eqb
          (ord bty1) (ord bty2)
  end.

(*
Instance x34_Eq : Eq basicType := {
   isEqual   :=  basicTypeEqual;
   isInequal  :=  fun  bty1  bty2 => negb (basicTypeEqual bty1 bty2)
}.


*)

Definition qualifiersEqual  (qs1 : qualifiers ) (qs2 : qualifiers ) : bool
  :=
  Bool.eqb (const qs1) (const  qs2)
  && (Bool.eqb (restrict  qs1) (restrict  qs2)
      && Bool.eqb (volatile  qs1) (volatile  qs2)).

(*
Instance x33_Eq : Eq qualifiers := {
   isEqual   :=  qualifiersEqual;
   isInequal  :=  fun  qs1  qs2 => negb (qualifiersEqual qs1 qs2)
}.
*)

Fixpoint ctypeEqual (fuel:nat) (cty0 cty1: ctype) : serr bool
  :=
  match fuel with
  | O => raise "out of fuel"
  | S fuel =>
      match cty0, cty1 with
      | (Ctype _ ty1), (Ctype _ ty2) =>
          let ord (x : ctype' ) :=
            match (x) with
            | Void => ( 0%nat : nat )
            | Basic _ => 1%nat
            | Array _ _ =>  2%nat
            | Function _ _ _ =>  3%nat
            | FunctionNoParams _ =>  4%nat
            | Pointer _ _ =>  5%nat
            | Atomic _ =>  6%nat
            | Struct _ =>  7%nat
            | Union _ =>  8%nat
            end
          in
          let paramsEqual fuel '(qs1,  ty1,  b1) '(qs2,  ty2,  b2) :=
            e <- ctypeEqual fuel ty1 ty2 ;;
            ret (qualifiersEqual qs1 qs2 && e && Bool.eqb b1 b2)
          in
          match ty1, ty2 with
          | Basic bty1, Basic bty2 =>
              ret (basicTypeEqual bty1 bty2)
          | Array ty1 n1_opt,  Array ty2 n2_opt =>
              e <- ctypeEqual fuel ty1 ty2 ;;
              ret (e && (maybeEqualBy Z.eqb n1_opt n2_opt))
          | Function (qs1,  ty1) params1 b1, Function (qs2,  ty2) params2 b2 =>
              e0 <- ctypeEqual fuel ty1 ty2 ;;
              e1 <- monadic_fold_left2
                     (fun acc b c => r <- paramsEqual fuel b c ;; ret (r && acc))
                     true
                     params1 params2
              ;;
              ret (qualifiersEqual qs1 qs2 && e0 && e1 && Bool.eqb b1 b2)
          | FunctionNoParams (qs1,  ty1), FunctionNoParams (qs2,  ty2) =>
              e <- ctypeEqual fuel ty1 ty2 ;;
              ret (qualifiersEqual qs1 qs2 && e)
          | Atomic ty1, Atomic ty2 => ctypeEqual fuel ty1 ty2
          | Struct id1, Struct id2 =>
              match id1, id2 with
              | Symbol d1 n1 sd1, Symbol d2 n2 sd2 =>
                  ret (Z.eqb (digest_compare d1 d2) 0 && Z.eqb n1 n2)
              end
          | Union id1, Union id2 =>
              match id1, id2 with
              | Symbol d1 n1 sd1,  Symbol d2 n2 sd2 =>
                  ret (Z.eqb (digest_compare d1 d2) 0 && Z.eqb n1 n2)
              end
          | _, _ =>
              ret (Nat.eqb (ord ty1) (ord ty2))
          end
      end
  end.

(*
Instance x32_Eq : Eq ctype := {
   isEqual   :=  ctypeEqual;
   isInequal  :=  fun  ty1  ty2 => negb (ctypeEqual ty1 ty2)
}.



Definition setElemCompare_integerBaseType  (ibty1 : integerBaseType ) (ibty2 : integerBaseType )  : ordering :=
  let ord := fun (x : integerBaseType ) =>
   match (x) with | Ichar => ( 0%nat : nat ) | Short =>  1%nat | Int_ =>
      2%nat | Long =>  3%nat | LongLong =>  4%nat | IntN_t _ =>  5%nat
     | Int_leastN_t _ =>  6%nat | Int_fastN_t _ =>  7%nat | Intmax_t =>
      8%nat | Intptr_t =>  9%nat end in
  match ( (ibty1, ibty2)) with
    | (IntN_t n1,  IntN_t n2) =>
        (genericCompare nat_ltb Nat.eqb n1 n2)
    | (Int_leastN_t n1,  Int_leastN_t n2) =>
        (genericCompare nat_ltb Nat.eqb n1 n2)
    | (Int_fastN_t n1,  Int_fastN_t n2) =>
        (genericCompare nat_ltb Nat.eqb n1 n2)
    | _ =>
        (genericCompare nat_ltb Nat.eqb (ord ibty1) (ord ibty2))
  end.

Instance x31_SetType : SetType integerBaseType := {
   setElemCompare  :=  setElemCompare_integerBaseType
}.


Definition setElemCompare_integerType  (ity1 : integerType ) (ity2 : integerType )  : ordering :=
  let ord := fun (x : integerType ) =>
   match (x) with | Char => ( 0%nat : nat ) | Bool =>  1%nat | Signed _ =>
      2%nat | Unsigned _ =>  3%nat | Enum _ =>  4%nat | Size_t =>  5%nat
     | Wchar_t =>  6%nat | Wint_t =>  7%nat | Ptrdiff_t =>  8%nat
     | Ptraddr_t =>  9%nat end in
  match ( (ity1, ity2)) with
    | (Signed ibty1,  Signed ibty2) =>
        setElemCompare_integerBaseType ibty1 ibty2
    | (Unsigned ibty1,  Unsigned ibty2) =>
        setElemCompare_integerBaseType ibty1 ibty2
    | (Enum sym1,  Enum sym2) =>
        ordCompare sym1 sym2
    | _ =>
        (genericCompare nat_ltb Nat.eqb (ord ity1) (ord ity2))
  end.

Instance x30_SetType : SetType integerType := {
   setElemCompare  :=  setElemCompare_integerType
}.



Definition setElemCompare_basicType  (bty1 : basicType ) (bty2 : basicType )  : ordering :=
  let ord := fun (x : basicType ) =>
   match (x) with | Integer _ => ( 0%nat : nat ) | Floating _ =>  1%nat end in
  match ( (bty1, bty2)) with
    | (Integer ity1,  Integer ity2) =>
        setElemCompare_integerType ity1 ity2
    | (Floating str1,  Floating str2) =>
        EQ
    | _ =>
        (genericCompare nat_ltb Nat.eqb (ord bty1) (ord bty2))
  end.

Instance x29_SetType : SetType basicType := {
   setElemCompare  :=  setElemCompare_basicType
}.



Instance x28_SetType : SetType qualifiers := {
   setElemCompare   qs1  qs2 :=
    (tripleCompare boolCompare boolCompare boolCompare ((const qs1),(restrict  qs1),(volatile  qs1))
                   ((const qs2),(restrict  qs2),(volatile  qs2)))
}.



Instance x27_Show : Show tag_definition := {
   show   def :=
    let string_of_identifiers := (fun  tag_defs =>
      String.append(List.fold_left (
  fun acc p =>
    match ( (acc ,p) ) with ( acc ,  (ident,  _)) =>
      String.append acc
        (String.append (match ( ident) with Identifier _ str => str end) "; ")
    end
      ) tag_defs "[") "]")
    in
    match ( def) with
      | StructDef tag_defs None =>
          string_of_identifiers tag_defs
      | StructDef tag_defs( Some( FlexibleArrayMember attrs ident qs elem_ty)) =>
          let ty := Ctype [] (Array elem_ty None) in
          string_of_identifiers ( (@ List.app _)tag_defs [(ident, (attrs, qs, ty))])
      | UnionDef tag_defs =>
          string_of_identifiers tag_defs
    end
}.

*)

(* [?]: removed value specification. *)

Definition proj_ctype'  (c: ctype): ctype'
  :=
  match c with Ctype _ ty_ => ty_ end.

(* NOTE: a well-formed ctype cannot have an Atomic inside another one *)
Definition unatomic (c: ctype)  : ctype
  :=
  match c with
    | Ctype annots1 ty_ as ty =>
        match ty_ with
        | Atomic ty => ty
        | _ => ty
        end
  end.

Definition unatomic_  (ty: ctype): ctype' :=
  proj_ctype' (unatomic ty).

(*
(* [?]: removed value specification. *)

Definition make_qualifiers  (c : bool ) (r : bool ) (v : bool )  : qualifiers :=  {|const    := c;restrict := r;volatile := v
|}.
(* [?]: removed value specification. *)
*)

Definition no_qualifiers   : qualifiers :=  {|const    := false;restrict := false;volatile := false
                                            |}.
(*
(* [?]: removed value specification. *)

Definition combine_qualifiers  (qs1 : qualifiers ) (qs2 : qualifiers )  : qualifiers :=  {|const    := ((const qs1)    ||(const  qs2))   ;restrict := ((restrict qs1) ||(restrict  qs2));volatile := ((volatile qs1) ||(volatile  qs2))
|}.

*)

(* Some constructors *)

Definition mk_ctype_pointer  (qs : qualifiers ) (ty : ctype )  : ctype :=
  Ctype nil (Pointer qs ty).

(*
Definition mk_ctype_integer  (ity : integerType )  : ctype :=
  Ctype [] (Basic (Integer ity)).

Definition mk_ctype_atomic  (c : ctype )  : ctype :=
  match ( (c)) with ( Ctype _ ty_ as cty) => let invalid :=
  match ( ty_) with | Array _ _ => true | Function _ _ _ => true
    | FunctionNoParams _ => true | Atomic _ => true | _ => false end in
  if invalid then
    FAKE_COQ.error "Ctyp.mk_ctype_atomic: called on an invalid inner type"
  else Ctype [] (Atomic cty) end.
(* [?]: removed value specification. *)
*)
Definition void   : ctype := Ctype nil Void.

Definition char   : ctype :=
  Ctype nil (Basic (Integer Char)).

Definition signed_char   : ctype :=
  Ctype nil (Basic (Integer (Signed Ichar))).

Definition signed_short   : ctype :=
  Ctype nil (Basic (Integer (Signed Short))).

Definition signed_int   : ctype :=
  Ctype nil (Basic (Integer (Signed Int_))).

Definition signed_long   : ctype :=
  Ctype nil (Basic (Integer (Signed Long))).

Definition signed_long_long   : ctype :=
  Ctype nil (Basic (Integer (Signed LongLong))).

Definition intptr_t   : ctype :=
  Ctype nil (Basic (Integer (Signed Intptr_t))).

Definition intmax_t   : ctype :=
  Ctype nil (Basic (Integer (Signed Intmax_t))).
Definition unsigned_char: ctype :=
  Ctype nil (Basic (Integer (Unsigned (Ichar)))).

Definition unsigned_short   : ctype :=
  Ctype nil (Basic (Integer (Unsigned Short))).

Definition unsigned_int   : ctype :=
  Ctype nil (Basic (Integer (Unsigned Int_))).

Definition unsigned_long   : ctype :=
  Ctype nil (Basic (Integer (Unsigned Long))).

Definition unsigned_long_long   : ctype :=
  Ctype nil (Basic (Integer (Unsigned LongLong))).

Definition uintptr_t   : ctype :=
  Ctype nil (Basic (Integer (Unsigned Intptr_t))).

Definition uintmax_t   : ctype :=
  Ctype nil (Basic (Integer (Unsigned Intmax_t))).

Definition char16_t   : ctype :=
  (* STD Â§7.28#2 *)
  Ctype nil (Basic (Integer (Unsigned (Int_leastN_t( 16%nat))))).

Definition char32_t   : ctype :=
  (* STD Â§7.28#2 *)
  Ctype nil (Basic (Integer (Unsigned (Int_leastN_t( 32%nat))))).

Definition wchar_t   : ctype :=
  Ctype nil (Basic (Integer Wchar_t)).

Definition size_t   : ctype :=
  Ctype nil (Basic (Integer Size_t)).

Definition ptrdiff_t   : ctype :=
  Ctype nil (Basic (Integer Ptrdiff_t)).

Definition ptraddr_t  ( _ : unit )  : ctype :=
  Ctype nil (Basic (Integer Ptraddr_t)).

(*

Definition is_ptr_t  (c : ctype )  : bool :=
  match ( (c)) with (( Ctype _ ty_)) =>
    match ( ty_) with | Basic( Integer( Signed Intptr_t)) => true
      | Basic( Integer( Unsigned Intptr_t)) => true | _ => false end end.
*)
