Require Import Common.
Require Import AilTypes AilSyntax AilTypesAux AilTypesAux_fun  AilTypesAux_proof.

(** definitions *)

Inductive isAdjusted : type -> Prop :=
 | IsAdjusted ty : ~ isArray    ty ->
                   ~ isFunction ty ->
                   isAdjusted   ty.

Definition isAdjusted_fun t : bool :=
  andb (negb (isArray_fun    t))
       (negb (isFunction_fun t)).

Lemma isAdjusted_fun_correct t :
  boolSpec (isAdjusted_fun t) (isAdjusted t).
Proof.
  do 2 unfold_goal.
  unfold andb.
  unfold negb.
  context_destruct; case_fun (isArray_fun_correct t).
  - inversion 1; contradiction.
  - context_destruct; case_fun (isFunction_fun_correct t).
    + inversion 1; contradiction.
    + constructor; assumption.
Qed.

(* defns JwfLvalue *)
Inductive wfLvalueType : qualifiers -> type -> Prop :=    (* defn wfLvalueType *)
 | WfLvalueTypeDefault : forall qs ty,
     ~ isPointer ty ->
     ~ (isRestrictQualified qs = true) ->
     ~ isFunction ty ->
     wfType ty ->
     wfLvalueType qs ty
 | WfLvalueTypeFunction : forall qs ty,
     ~ isPointer ty ->
     isFunction ty ->
     isUnqualified qs ->
     wfType ty ->
     wfLvalueType qs ty
 | WfLvalueTypePointerToObject : forall (qs' qs:qualifiers) (ty:type),
     isObject ty ->
     wfType (Pointer qs ty) ->
     wfLvalueType qs' (Pointer qs ty)
 | WfLvalueTypePointerToOther : forall (qs' qs:qualifiers) (ty:type),
     ~ isObject ty ->
     ~ (isRestrictQualified qs' = true) ->
     wfType (Pointer qs ty) ->
     wfLvalueType qs' (Pointer qs ty) 
with wfType : type -> Prop :=    (* defn wfType *)
 | WfTypeVoid : 
     wfType Void
 | WfTypeBasicType : forall (basicType:basicType),
     wfType (Basic basicType)
 | WfTypeArray : forall (ty:type) (n:nat),
     isComplete ty ->
     wfType ty ->
     wfType (Array ty n) 
 | WfTypeFunction : forall ty p,
     ~ isArray ty ->
     ~ isFunction ty ->
     wfType ty ->
     wfParams p ->
     wfType (Function ty p) 
 | WfTypePointer : forall (qs:qualifiers) (ty:type),
     wfLvalueType qs ty ->
     wfType (Pointer qs ty) 
with wfParams : params -> Prop :=
 | WfParamsNil          : wfParams ParamsNil
 | WfParamsCons qs ty p :
     isAdjusted ty ->
     ~ isIncomplete ty ->
     wfLvalueType qs ty ->
     wfParams p ->
     wfParams (ParamsCons qs ty p).

Definition wfLvalueType_incl qs ty :
  wfLvalueType qs ty -> wfType ty.
Proof.
  destruct ty;
  inversion 1;
  finish ltac:(now
    match goal with
    | [H : ~ isPointer  (Pointer _ _) |- _] => exfalso; apply H; constructor
    | [H :   isFunction (Array   _ _) |- _] => inversion H
    end
  ).
Qed.

Fixpoint wfType_fun ty : bool :=
  match ty with
  | Void
  | Basic _ => true
  | Array ty _    => andb (isComplete_fun ty)
                          (wfType_fun     ty)
  | Function ty p => andb (andb (negb (isArray_fun    ty))
                                (negb (isFunction_fun ty)))
                          (andb (wfType_fun  ty)
                                (wfParams_fun p))
  | Pointer qs ty => andb (wfType_fun ty)
                          (wfLvalueType_aux_fun qs ty)
  end
with wfParams_fun p : bool :=
  match p with
  | ParamsNil => true
  | ParamsCons qs ty p =>
      andb (andb (isAdjusted_fun ty)
                 (negb (isIncomplete_fun ty)))
           (andb (wfType_fun ty)
                 (andb (wfLvalueType_aux_fun qs ty)
                       (wfParams_fun p)))
  end
with wfLvalueType_aux_fun qs ty : bool :=
  match ty with
  | Pointer qs' ty' => implb (negb (isObject_fun ty')) (negb (isRestrictQualified qs))
  | _               => if isFunction_fun ty
                         then isUnqualified_fun qs 
                         else negb (isRestrictQualified qs) 
  end.

Definition wfLvalueType_fun qs ty : bool :=
  andb (wfType_fun ty) (wfLvalueType_aux_fun qs ty).

Fixpoint wfType_fun_correct ty :
  boolSpec (wfType_fun ty) (wfType ty)
with wfParams_fun_correct p :
  boolSpec (wfParams_fun p) (wfParams p)
with wfLvalueType_aux_fun_correct qs ty :
  wfType ty -> 
  boolSpec (wfLvalueType_aux_fun qs ty) (wfLvalueType qs ty).
Proof.
- destruct ty; simpl;
  unfold boolSpec; unfold andb; unfold negb;
  repeat match goal with
  | [|- wfType_fun     ?t = _ -> _] => case_fun (wfType_fun_correct     t)
  | [|- wfParams_fun   ?p = _ -> _] => case_fun (wfParams_fun_correct   p)
  | [|- isComplete_fun ?t = _ -> _] => case_fun (isComplete_fun_correct t)
  | [|- isArray_fun    ?t = _ -> _] => case_fun (isArray_fun_correct    t)
  | [|- isFunction_fun ?t = _ -> _] => case_fun (isFunction_fun_correct t)
  | [H : wfType ?ty |- wfLvalueType_aux_fun ?qs ?ty = _ -> _] => case_fun (wfLvalueType_aux_fun_correct qs ty H)
  | [|- wfType _] => econstructor (eassumption)
  | [Hfalse : neg (wfType ?t), H : wfLvalueType _ ?t |- False] => exact (Hfalse (wfLvalueType_incl _ _ H))
  | [|- neg _] => inversion 1; subst; try finish contradiction
  | _ => boolSpec_simpl; try context_destruct
  end.
- destruct p; simpl;
  unfold boolSpec; unfold andb; unfold negb;
  repeat match goal with
  | [|- wfType_fun     ?t = _ -> _] => case_fun (wfType_fun_correct     t)
  | [|- wfParams_fun   ?p = _ -> _] => case_fun (wfParams_fun_correct   p)
  | [|- isIncomplete_fun ?t = _ -> _] => case_fun (isIncomplete_fun_correct t)
  | [|- isAdjusted_fun    ?t = _ -> _] => case_fun (isAdjusted_fun_correct    t)
  | [H : wfType ?ty |- wfLvalueType_aux_fun ?qs ?ty = _ -> _] => case_fun (wfLvalueType_aux_fun_correct qs ty H)
  | [|- wfParams _] => econstructor (eassumption)
  | [Hfalse : neg (wfType ?t), H : wfLvalueType _ ?t |- False] => exact (Hfalse (wfLvalueType_incl _ _ H))
  | [|- neg _] => inversion 1; subst; try finish contradiction
  | _ => boolSpec_simpl; try context_destruct
  end.
- intros ?; destruct ty; simpl;
  unfold boolSpec; unfold implb; unfold negb;
  repeat match goal with
  | [|- isObject_fun ?t = _ -> _] => case_fun (isObject_fun_correct t)
  | [|- isFunction_fun ?t = _ -> _] => case_fun (isFunction_fun_correct t)
  | [|- isRestrictQualified ?qs = ?b -> _] => destruct b; [|rewrite <- Bool.not_true_iff_false]; intros ?
  | [|- isUnqualified_fun ?qs = _ -> _] => case_fun (isUnqualified_fun_correct qs)
  | [|- wfLvalueType _ _] => econstructor (finish eassumption)
  | [|- neg _] => inversion 1; finish ltac:(now match goal with
                                                | [H :   isFunction Void           |- _] => inversion H
                                                | [H :   isFunction (Basic      _) |- _] => inversion H
                                                | [H :   isFunction (Array    _ _) |- _] => inversion H
                                                | [H :   isFunction (Pointer  _ _) |- _] => inversion H
                                                | [H : ~ isFunction (Function _ _) |- _] => exfalso; apply H; constructor
                                                end
                                           )
  | _ => boolSpec_simpl; try context_destruct
  end.
Qed.

Lemma wfLvalueType_fun_correct qs ty :
  boolSpec (wfLvalueType_fun qs ty) (wfLvalueType qs ty).
Proof.
  do 2 unfold_goal; unfold andb.
  context_destruct; case_fun (wfType_fun_correct ty).
  + context_destruct; case_fun (wfLvalueType_aux_fun_correct qs ty); tauto.
  + inversion 1; finish fail.
Qed.
