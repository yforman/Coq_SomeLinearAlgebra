(* The goal of this document is to prove the spectral theorem for finite-dimensional 
symmetric matrices over the real numbers. 
On the way we hope to learn how to use real numbers and matrices in Coq / mathcomp. *)


From mathcomp Require Import all_ssreflect all_algebra all_field ssralg ssrint ssrnum.
From mathcomp.analysis Require Import reals.
From mathcomp.algebra_tactics Require Import ring.
Import GRing.Theory Num.Theory.
Import Num.Def.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* Some practice with \sum, which could come in handy for dealing with vector inner products: *)
Lemma sumofones (m n : nat) : \sum_(m <= i < n + m) 1 = n.
Proof.
generalize m.
induction n as [| n' IHn].
- intros m0. apply big_geq. rewrite add0n //.
- intros m0. rewrite big_ltn. assert (ind : n'.+1 + m0 = n' + m0.+1). {apply addSnnS. } 
  rewrite ind. rewrite IHn //. 
  rewrite addnC addnS.
  apply (leq_addr n' m0).
Qed.


Local Open Scope ring_scope.

Variable R: realType.


(* Build a function that adds 2.5 to a real number. *)
Definition add_two_and_a_half (x : R) : R := x + (2 + 1/2).

Check add_two_and_a_half.
Check add_two_and_a_half 6.
Compute add_two_and_a_half 6.

Lemma six_and_two_and_a_half_make_eight_and_a_half : add_two_and_a_half 6 = (8 + 1/2).
Proof.
unfold add_two_and_a_half.
by ring.
Qed.

(* Build a function that multiplies a real number by sqrt2. *)
Definition multiply_by_sqrt_2 (x : R) : R := x * Num.sqrt(2).

Check multiply_by_sqrt_2.
Check multiply_by_sqrt_2 1.

Lemma sqrt2_times_sqrt2_is_2 : multiply_by_sqrt_2 (Num.sqrt 2) = 2.
Proof.
unfold multiply_by_sqrt_2.
rewrite <- sqr_sqrtr.
- reflexivity.
- apply ler0n. 
Qed.

(* Build a specific matrix. *)

Definition M1 : 'M[R]_5 := const_mx 12.

Definition M2 : 'M[R]_5 := \matrix_(i < 5, j < 5) 0.

Definition M3 : 'M[R]_5 := \matrix_(i < 5, j < 5) if i==j then 1 else 2.

Definition M4 : 'M[R]_5 := M1 + M3.

Definition M5 : 'M[R]_5 := \matrix_(i < 5, j < 5) if i==0 then 1 else 0.

Definition M6 : 'M[R]_5 := \matrix_(i < 5, j < 5) if i==j then 13 else 14.

(*Compare some concrete matrices entrywise to show they are equal:*)
Lemma comp_matrices : M4 = M6.
Proof.
apply matrixP=> i j. rewrite !mxE.
destruct (i==j) eqn:H.
- rewrite H. by ring.
- rewrite H. by ring.
Qed.

Definition constmx1 : 'M[R]_1 := const_mx 1.

Lemma comp_m2 : constmx1 = 1%:M.
Proof.
apply matrixP=> i j. rewrite !mxE.
destruct (i==j) eqn:H.
- rewrite H. reflexivity.
- destruct i as [p i]. destruct j as [q j]. destruct p. destruct q.
  + assert(oreq : Ordinal i = Ordinal j). {apply ord_inj. reflexivity. }
    rewrite oreq in H. discriminate.
  + discriminate.
  + discriminate.
Qed.

(* Some useful, simple lemmata about matrix addition with 0: *)
Lemma addM0 {m n : nat} (M : 'M[R]_(m,n)) : M + 0 = M.
Proof.
apply matrixP=> i j. rewrite !mxE. apply addr0.
Qed.

Lemma add0M {m n : nat} (M : 'M[R]_(m,n)) : 0 + M = M.
apply matrixP=> i j. rewrite !mxE. apply add0r.
Qed.



(* State and prove: if A and B are matrices with a simultaneous eigenvector, 
then A+B has the same eigenvector. *)

(* Note that the mathcomp library has a definition of eigenvalue/eigenvector, 
but it uses a left row vector and doesn't have an eigenpair statement, 
so I'd like to write my own. *)

Section mxn. (*Definitions and lemmas applying specifically to matrices/vectors of size n.*)
Variable (n : nat).

Definition eigenpair (M : 'M[R]_n) (lambda : R) (v : 'cV[R]_n) : Prop := 
  v != 0 /\ M *m v = lambda *: v.

Definition eigenval (lambda : R) (M : 'M[R]_n) : Prop := 
  exists v : 'cV[R]_n, eigenpair M lambda v.

Definition eigenvec (v : 'cV[R]_n) (M : 'M[R]_n) : Prop :=
  exists lambda:R, eigenpair M lambda v.

Definition simul_eigenvec (v : 'cV[R]_n) (A B : 'M[R]_n) : Prop := 
  ((exists l1:R, eigenpair A l1 v) /\ (exists l2:R, eigenpair B l2 v)).

Lemma simul_eigenval_sum : forall (v : 'cV[R]_n) (A B : 'M[R]_n), simul_eigenvec v A B -> eigenvec v (A+B).
Proof.
intros v A B H. unfold simul_eigenvec in H.
unfold eigenvec. unfold eigenpair.
destruct H as [HA HB]. destruct HA as [lA HA]. destruct HB as [lB HB].
unfold eigenpair in HA. destruct HA as [_ HA].
unfold eigenpair in HB. destruct HB as [vnonzero HB].
exists (lA+lB). split. apply vnonzero.
assert (dist : (A + B) *m v = A *m v + B *m v). {apply mulmxDl. } rewrite dist HA HB.
symmetry. apply (scalemxDl v lA lB).
Qed.


(* Now onto the spectral theorem. We will admit the fact that all symmetric real matrices 
have one eigenvalue -- proofs of this fact of which I am aware go either through 
complexification and the fundamental theorem of algebra, or through an optimization argument 
on the Rayleigh quotient. Both are beyond the scope of the current project. *)

Definition symmx (M : 'M[R]_n) : Prop := M = M^T. (* Definition of a symmetric matrix. *)

Lemma symmx_has_eigenvalue : forall (M : 'M[R]_n), (n > 0)%N -> symmx M -> exists l:R, eigenval l M.
Admitted.

Definition orthmx (M : 'M[R]_n) : Prop := M *m (M^T) = 1%:M. (* Definition of orthogonal matrix .*)

Lemma orthmx_prod : forall (M N : 'M[R]_n), orthmx M -> orthmx N -> orthmx (M *m N).
  (*Product of orthogonal matrices is orthogonal.*)
Proof.
intros M N HM HN. unfold orthmx. unfold orthmx in HM. unfold orthmx in HN.
rewrite trmx_mul. rewrite <- mulmxA. rewrite (mulmxA N N^T M^T).
rewrite HN mul1mx HM. reflexivity.
Qed.

Definition one_dirp (M: 'M[R]_n) : 'M[R]_n.+1 :=
  (*Adding a one to the top left corner and 0s in the rest of its row/column*)
  block_mx (1%:M : 'M[R]_1) 0 0 M.

Lemma one_dirp_tr : forall (M : 'M[R]_n), (one_dirp M)^T = one_dirp M^T.
Proof.
intros M. unfold one_dirp. (*rewrite tr_mxdiag. apply eq_mxdiag. intros i. apply one_dirp_comp_tr.*)
rewrite (tr_block_mx (1%:M : 'M[R]_1) 0 0 M). rewrite trmx1 !trmx0 //.
Qed.

(* Multiplying block diagonal matrices with two blocks :*)
Lemma block_diag_mulmx {m : nat} : forall (M N : 'M[R]_n) (A B : 'M[R]_m), 
  block_mx A 0 0 M *m block_mx B 0 0 N = block_mx (A *m B) 0 0 (M *m N).
Proof.
intros M N A B. rewrite mulmx_block. rewrite !mulmx0 !mul0mx !addM0 !add0M //.
Qed.

(* The specific case of the latter lemma when the topleft blocks are single 1s: *)
Lemma one_dirp_mulmx : forall (M N : 'M[R]_n), one_dirp M *m one_dirp N = one_dirp (M *m N).
Proof.
intros M N. unfold one_dirp.
rewrite (block_diag_mulmx M N (1%:M : 'M[R]_1) (1%:M : 'M[R]_1)). rewrite mulmx1 //.
Qed.

Lemma one_dirp_id : one_dirp 1%:M  = 1%:M.
Proof.
symmetry. rewrite (scalar_mx_block 1 n 1) //.
Qed.


(* A symmetric matrix maps the orthogonal complement of an eigenvector to itself: *)
Lemma symmx_maps_orthcomp_to_itself : forall (M : 'M[R]_n) (v : 'cV[R]_n) (w : 'rV[R]_n), 
  symmx M -> eigenvec v M -> (w <= kermx v)%MS -> (w *m M <= kermx v)%MS.
Proof.
intros M v w Msym eigvM subs.
rewrite sub_kermx.
unfold eigenvec in eigvM. destruct eigvM as [lambda eigvM].
unfold eigenpair in eigvM. destruct eigvM as [_ eigvM].
rewrite sub_kermx in subs.
rewrite <- mulmxA. rewrite eigvM.
assert (po : w *m (lambda *: v) = lambda *: (w *m v)). {symmetry. apply (scalemxAr lambda w v). }
rewrite po.
rewrite scalemx_eq0.
rewrite subs.
rewrite Bool.orb_true_r.
apply is_true_true.
Qed.

(* Define vector norms and normalization: *)
Definition normsqR (v : 'rV[R]_n) : R := (v *m v^T) 0 0.

Definition normsqC (v : 'cV[R]_n) : R := (v^T *m v) 0 0.

Definition normR (v : 'rV[R]_n) : 'rV[R]_n := (1/Num.sqrt(normsqR v)) *: v.

Definition normC (v : 'cV[R]_n) : 'cV[R]_n := (1/Num.sqrt(normsqC v)) *: v.

Definition is_normalR (v : 'rV[R]_n) : Prop := normsqR v = 1.

Definition is_normalC (v : 'cV[R]_n) : Prop := normsqC v = 1.

(* Two useful lemmata I couldn't find on mathcomp: *)
Lemma tr_mul {m : nat} (a : R) (A : 'M[R]_(m,n)) : (a *: A)^T = a *: A^T.
Proof.
rewrite <- !mul_scalar_mx. rewrite trmx_mul. rewrite tr_scalar_mx.
apply scalar_mxC.
Qed.

Lemma ssmx_mul {m p : nat} (a b : R) (A : 'M[R]_(m,p)) : a *: (b *: A) = (b * a) *: A.
Proof.
rewrite <- !mul_scalar_mx. rewrite mulmxA. rewrite mul_mx_scalar. rewrite scale_scalar_mx.
reflexivity.
Qed.

(* Recasting the size of the matrix to split off the first entry of a row/column vector: *)
Lemma suc_eq : n.+1 = (1 + n)%N.
Proof.
symmetry. apply add1n.
Qed.

Definition splitofR (v : 'rV[R]_n.+1) : 'rV[R]_(1 + n) := castmx (erefl 1%N, suc_eq) v.

Definition splitofC (v : 'cV[R]_n.+1) : 'cV[R]_(1 + n) := castmx (suc_eq, erefl 1%N) v.

Lemma splitR' (v : 'rV[R]_n.+1) (o : 'I_1) (i : 'I_n.+1) : v o i = (splitofR v) o (cast_ord suc_eq i).
Proof.
rewrite castmxE /= cast_ordK cast_ord_id //.
Qed.

Lemma splitR (v : 'rV[R]_n.+1) (o : 'I_1) (i : 'I_n.+1) : v o i = (splitofR v) o i.
Proof.
assert (ordeq : cast_ord suc_eq i = i). {apply ord_inj. reflexivity. } 
rewrite splitR' ordeq //.
Qed.

Lemma splitC' (v : 'cV[R]_n.+1) (o : 'I_1) (i : 'I_n.+1) : v i o = (splitofC v) (cast_ord suc_eq i) o.
Proof.
rewrite castmxE /= cast_ordK cast_ord_id //.
Qed.

Lemma splitC (v : 'cV[R]_n.+1) (o : 'I_1) (i : 'I_n.+1) : v i o = (splitofC v) i o.
Proof.
assert (ordeq : cast_ord suc_eq i = i). {apply ord_inj. reflexivity. } 
rewrite splitC' ordeq //.
Qed.

Lemma split_prod (rv : 'rV[R]_n.+1) (cv : 'cV[R]_n.+1) :
  rv *m cv = splitofR rv *m splitofC cv.
Proof.
apply matrixP=> i j. rewrite !mxE. apply eq_bigr. intros i0 true.
rewrite splitR splitC //.
Qed. 

Lemma split_tr (v : 'rV[R]_n.+1) : (splitofR v)^T = splitofC v^T.
Proof.
apply matrixP=> i j. rewrite <- splitC. rewrite !mxE. symmetry. apply splitR.
Qed.

End mxn.

(*Showing vector norms are nonnegative and positive when nonzero:*)
(*First, we show that the square of a nonzero real is nonzero:*)
Lemma sqnz (x : R) : x != 0 -> x * x > 0.
Proof.
intros H. 
assert (notodd2 : ~~odd 2). {reflexivity. }
rewrite (exprn_even_gt0 x notodd2).
rewrite H. 
rewrite Bool.orb_true_r.
apply is_true_true.
Qed.

(*We show nonnegativity, then positivity when nonzero, for one-dimensional vectors:*)
Lemma normRpos1 (v : 'rV[R]_1) : normsqR v >= 0.
Proof.
unfold normsqR. rewrite !mxE. rewrite big_ord_recl big_ord0 mxE addr0. apply sqr_ge0.
Qed.

Lemma normRnz1 (v : 'rV[R]_1) : v !=0 -> normsqR v > 0.
Proof.
unfold normsqR. rewrite !mxE. rewrite big_ord_recl big_ord0 mxE addr0.
move /cV0Pn. intros H. destruct H as [i].
assert (ordeq : i = 0). 
  {destruct i as [m i]. destruct m.
  - apply ord_inj. reflexivity.
  - discriminate. } 
rewrite ordeq in H.
apply (sqnz H).
Qed.

(* Now for general vectors: *)
Lemma normRpos {n : nat} (v : 'rV[R]_n) : normsqR v >= 0.
Proof.
induction n as [| n' IH].
- unfold normsqR. rewrite !mxE. rewrite big_ord0 //.
- unfold normsqR. rewrite split_prod. rewrite <- split_tr. 
  rewrite <- (hsubmxK (splitofR v)). rewrite tr_row_mx. 
  rewrite mul_row_col. rewrite mxE.
  rewrite <- (addr0 0). rewrite ler_add. apply is_true_true. apply normRpos1. apply IH.
Qed.

Lemma normCpos {n : nat} (v : 'cV[R]_n) : normsqC v >= 0.
Proof.
unfold normsqC. rewrite <- (trmxK v). rewrite (trmxK v^T). apply normRpos.
Qed.

Lemma normRnzp {n : nat} (v : 'rV[R]_n) : v != 0 -> normsqR v > 0.
Proof.
intros H. induction n as [|n' IH].
- assert (H0 : v==0). {rewrite thinmx0 //. } rewrite H0 in H. discriminate.
- unfold normsqR. rewrite split_prod. rewrite <- split_tr.
  rewrite <- (hsubmxK (splitofR v)). rewrite tr_row_mx.
  rewrite mul_row_col. rewrite mxE. 
  destruct (lsubmx (splitofR v)==0) eqn:HL. destruct (rsubmx (splitofR v)==0) eqn:HR.
  + (* both submatrices 0 *) assert (s0 : splitofR v = 0). 
    { apply: eqP. rewrite <- (hsubmxK (splitofR v)). rewrite row_mx_eq0 HL HR. reflexivity. }
    assert (v0 : v=0). { rewrite <- (castmxK (erefl 1%N) (suc_eq n') v). 
    assert (s : castmx (erefl 1%N, suc_eq n') v = splitofR v). {reflexivity. }
    rewrite s s0. apply castmx_const. }
    assert (v0' : v==0). { rewrite v0 //. }
    rewrite v0' in H. discriminate.
  + (* right submatrix nonzero *) rewrite <- (addr0 0). apply ler_lt_add. 
    apply normRpos1. apply IH. rewrite HR //.
  + (* left submatrix nonzero *) rewrite <- (addr0 0). apply ltr_le_add.
    apply normRnz1. rewrite HL //. apply normRpos.
Qed.

Lemma normRnz {n : nat} (v : 'rV[R]_n) : v != 0 -> normsqR v != 0.
Proof.
intros H. apply lt0r_neq0. apply normRnzp. apply H.
Qed.

Lemma normCnz {n : nat} (v : 'cV[R]_n) : v != 0 -> normsqC v != 0.
Proof.
intros H. unfold normsqC. rewrite <- (trmxK v). rewrite (trmxK v^T). apply normRnz.
rewrite trmx_eq0. apply H.
Qed.


Section mxn. (*Definitions and lemmas applying specifically to matrices/vectors of size n.*)
Variable (n : nat).

(*Normalizing a nonzero vector makes it normal:*)
Lemma normR_is_normal (v : 'rV[R]_n) : v != 0 -> is_normalR (normR v).
Proof.
intros vnz. unfold is_normalR. unfold normsqR. unfold normR. rewrite tr_mul.
rewrite <- !mul_scalar_mx. rewrite mulmxA. 
assert (temp : (1 / Num.sqrt (normsqR v))%:M *m v *m (1 / Num.sqrt (normsqR v))%:M *m v^T = const_mx 1).
{rewrite <- (mulmxA (1 / Num.sqrt (normsqR v))%:M v (1 / Num.sqrt (normsqR v))%:M).
rewrite scalar_mxC. rewrite mulmxA. rewrite mul_mx_scalar scale_scalar_mx.
rewrite <- mulmxA. 
rewrite mulf_div.
assert (temp' : Num.sqrt (normsqR v) * Num.sqrt (normsqR v) = normsqR v ).
{apply sqr_sqrtr. apply normRpos. }
rewrite temp'. rewrite mul_scalar_mx.
assert (temp'' : v *m v^T = const_mx (normsqR v)).
{unfold normsqR. apply matrixP=> i j. rewrite !mxE.
destruct i as [p i]. destruct j as [q j].
destruct p. destruct q. 
assert (Hi : Ordinal i = 0). {apply ord_inj. reflexivity. }
assert (Hj : Ordinal j = 0). {apply ord_inj. reflexivity. }
rewrite Hi Hj. reflexivity. discriminate. discriminate. }
rewrite temp'' scalemx_const. apply matrixP => i j. rewrite !mxE. 
rewrite mul1r. rewrite mul1r. apply mulVf. apply normRnz. apply vnz. }
rewrite temp. rewrite !mxE. reflexivity.
Qed.

(*A different, useful characerization of a normal vector:*)
Lemma normal_to_id (v : 'rV[R]_n) : is_normalR v -> v *m v^T = 1%:M.
Proof.
intros H. unfold is_normalR in H. unfold normsqR in H.
apply matrixP=> i j. destruct i as [p i]. destruct j as [q j].
destruct p. destruct q.
assert (Hi : Ordinal i = 0). {apply ord_inj. reflexivity. }
assert (Hj : Ordinal j = 0). {apply ord_inj. reflexivity. }
rewrite Hi Hj H. rewrite mxE. reflexivity. discriminate. discriminate.
Qed.

(* We need a procedure to develop a single unit vector into an orthogonal matrix. *)
(* For this, it will be helpful to first define the notion of a set of orthonormal (row) 
vectors, then show that if there are fewer than n vectors in the set, we can 
add a vector to the set. *)
Definition orthvecs {m : nat} (V : 'M[R]_(m,n)) := V *m V^T = 1%:M.

(* Show orthognality: *)
Lemma orthvecs_orth {m m' : nat} (V : 'M[R]_(m,n)) (W : 'M[R]_(m',n)) :
  orthvecs (col_mx V W) -> W *m V^T = 0.
Proof.
unfold orthvecs. intros H. rewrite tr_col_mx mul_col_row in H. 
rewrite scalar_mx_block in H. apply (eq_block_mx H).
Qed.

(* Adding a normal vector in the cokernel will preserve orthogonality: *)
Lemma add_orthvec' {m : nat} (V : 'M[R]_(m,n)) (v : 'rV[R]_n) :
  orthvecs V -> is_normalR v -> V *m v^T = 0 -> orthvecs (col_mx V v).
Proof.
intros orthV normalv kernelv. unfold orthvecs. rewrite tr_col_mx mul_col_row.
rewrite orthV kernelv (normal_to_id normalv).
assert (kernelvT : v *m V^T = 0). {
  rewrite <- (trmxK v).  
  rewrite <- (trmxK (V *m v^T)) in kernelv. rewrite (trmx_mul V v^T) in kernelv.
  rewrite <- trmx0. rewrite <- (trmxK ((v^T)^T *m V^T)).
  rewrite kernelv //. }
rewrite kernelvT. symmetry. apply scalar_mx_block.
Qed.

(* As long as there are fewer than n vectors, we can find such a normal vector to add: *)
Lemma add_orthvec {m : nat} (V: 'M[R]_(m,n)) : (m < n)%N -> orthvecs V -> 
  exists (v : 'rV[R]_n), orthvecs (col_mx V v).
Proof.
intros mltn orthV.
assert (nrf : ~~ row_free V^T). {
  rewrite <- row_leq_rank. rewrite <- ltnNge.
  apply (leq_ltn_trans (rank_leq_col V^T) mltn). }
rewrite <- kermx_eq0 in nrf.
exists (normR (nz_row (kermx V^T))).
assert (normalv : is_normalR (normR (nz_row (kermx V^T)))). {
  apply normR_is_normal. rewrite nz_row_eq0. apply nrf. }
assert (kernelv : V *m (normR (nz_row (kermx V^T)))^T = 0). {
  unfold normR. rewrite tr_mul. rewrite <- !mul_scalar_mx. rewrite mulmxA. 
  rewrite scalar_mxC. rewrite <- mulmxA.
  assert (righths : V *m (nz_row (kermx V^T))^T = 0). {
    apply trmx_inj. rewrite trmx_mul. rewrite trmxK trmx0.
    apply: sub_kermxP. apply nz_row_sub. }
  rewrite righths. apply mulmx0. }
apply (add_orthvec' orthV normalv kernelv).
Qed. 

(* To add multiple vectors, we will need to typecast the matrix dimensions. 
The following lemmas should help. *)
Definition nested_exp (m p : nat) : nat := match p with 
| 0 => m + 0
| S q => m + q + 1
end.

Lemma nested_eq (m p : nat) : nested_exp m p = (m + p)%N.
Proof.
symmetry. destruct p as [|q].
- reflexivity.
- rewrite <- addn1. rewrite addnA (addn1 q) //.
Qed.

Lemma orthvecs_cast {m p : nat} (V : 'M[R]_((nested_exp m p),n)) : 
  orthvecs V -> orthvecs (castmx (nested_eq m p, erefl n) V).
Proof.
unfold orthvecs. intros H. apply matrixP=> i j. rewrite !mxE. 
assert (eqsum : \sum_j0
   castmx (nested_eq m p, erefl n) V i j0 *
   (castmx (nested_eq m p, erefl n) V)^T j0 j = 
  \sum_j0 V (cast_ord (esym(nested_eq m p)) i) j0 * 
    V^T j0 (cast_ord (esym(nested_eq m p)) j)). {
  apply eq_bigr. intros i0 true. rewrite !mxE !castmxE /=.
  assert (ordeq : cast_ord (erefl n) i0 = i0). {apply ord_inj. reflexivity. }
  rewrite !ordeq //. }
rewrite eqsum.
assert (mulsum : \sum_j0 V (cast_ord (esym (nested_eq m p)) i) j0 * V^T j0 (cast_ord (esym (nested_eq m p)) j) = (V *m V^T) (cast_ord (esym (nested_eq m p)) i) (cast_ord (esym (nested_eq m p)) j)).
{ rewrite mxE //. }
rewrite mulsum H mxE //.
Qed.

(* We are now ready for the general lemma that a set of orthogonal vectors can be expanded 
up to n vectors and remain a set of orthogonal vectors. *)
Lemma add_orthvecs {m : nat} (p : nat) (V : 'M[R]_(m,n)) : (m < n)%N -> (m + p <= n)%N ->
  orthvecs V -> exists (W : 'M[R]_(p,n)), orthvecs (col_mx V W).
Proof.
intros mltn mplen orthV. 
induction p as [| p' IH].
- exists 0. unfold orthvecs. rewrite tr_col_mx. rewrite mul_col_row. rewrite orthV.
  assert (flatid : (0 : 'M[R]_(0,n)) *m 0 = (1%:M : 'M[R]_0)). {
    rewrite mul0mx. symmetry. apply (flatmx0 1%:M). }
  rewrite mul0mx trmx0 mulmx0 flatid. symmetry. apply scalar_mx_block.
- rewrite (addnS m p') in mplen. 
  assert (mplen' : ((m + p') <= n)%N). {apply ltnW. apply mplen. }
  assert (IH' : exists W : 'M_(p', n), orthvecs (col_mx V W)). {apply IH. apply mplen'. }
  destruct IH' as [W' IH']. 
  assert (vec : exists (v : 'rV[R]_n), orthvecs (col_mx (col_mx V W') v)). {
    apply (add_orthvec mplen IH'). }
  destruct vec as [v vec]. 
  exists (dsubmx (castmx (nested_eq m p'.+1, erefl n) (col_mx (col_mx V W') v))).
  assert (Vu : V = usubmx (castmx (nested_eq m p'.+1, erefl n) (col_mx (col_mx V W') v))). {
    apply matrixP=> i j. rewrite mxE castmxE.
    assert (ls : (cast_ord (esym (nested_eq m p'.+1, erefl n).1) (lshift p'.+1 i)) = 
                lshift 1 (lshift p' i) ). {
      apply ord_inj. reflexivity. }
    assert (rs : (cast_ord (esym (nested_eq m p'.+1, erefl n).2) j) = j). {
      apply ord_inj. by []. }
    rewrite ls !col_mxEu rs //. }
  rewrite [in V in orthvecs (col_mx V _)]Vu.
  rewrite vsubmxK.
  apply orthvecs_cast.
  apply vec.
Qed.

End mxn.

(* Special case of the latter lemma for expanding a single vector into an orthogonal matrix :*)
Lemma vec_to_orthmx {n : nat} (v : 'rV[R]_n.+1) : is_normalR v -> 
  exists (W : 'M[R]_(n,n.+1)), orthmx (col_mx v W).
Proof.
intros normv.
assert (orthv : orthvecs v). {apply normal_to_id. apply normv. }
destruct n as [| n'].
- exists 0. unfold orthmx. rewrite tr_col_mx. rewrite mul_col_row. rewrite orthv.
  assert (flatid : (0 : 'M[R]_(0,1)) *m 0 = (1%:M : 'M[R]_0)). {
    rewrite mul0mx. symmetry. apply (flatmx0 1%:M). }
  rewrite mul0mx trmx0 mulmx0 flatid. symmetry. apply scalar_mx_block.
- assert (mltn : (1 < n'.+2)%N). {reflexivity. }
  assert (mplen : (1 + n'.+1 <= n'.+2)%N). {rewrite addnS //. }
  destruct (add_orthvecs mltn mplen orthv) as [W H].
  exists W. apply H.
Qed.

(* Adding a 1 above and to the left of an orthogonal matrix preserves its orthogonality. *)
Lemma one_dirp_pres_orth : forall (n : nat) (M : 'M[R]_n), orthmx M -> orthmx (one_dirp M).
Proof.
intros n M H. unfold orthmx. rewrite one_dirp_tr one_dirp_mulmx.
unfold orthmx in H. rewrite H. apply one_dirp_id.
Qed.

(* The first step of spectral decomposition: putting a single eigenvalue on the diagonal *)
Lemma spec1 {n : nat} (M : 'M[R]_n.+1) : symmx M -> 
  exists (U : 'M[R]_n.+1) (M' : 'M[R]_n) (lambda : R), 
  orthmx U /\ symmx M' /\ U *m M *m U^T = block_mx (lambda%:M : 'M[R]_1) 0 0 M'.
Proof.
intros H. destruct (symmx_has_eigenvalue (ltn0Sn n) H) as [lambda Heig].
destruct Heig as [v Heig]. destruct Heig as [vnz Heig].
assert (vtnz : v^T != 0). { 
  destruct (v^T == 0) eqn:vtz. assert (vz : v=0). {apply trmx_inj. apply: eqP. rewrite trmx0 //. }
  assert (vz' : v==0). {rewrite vz //. } rewrite vz' in vnz. discriminate. reflexivity. }
destruct (vec_to_orthmx (normR_is_normal vtnz)) as [W oU].
exists (col_mx (normR v^T) W).
assert (Heigt : v^T *m M = lambda *: v^T). {
  rewrite H. assert (t : v^T *m M^T = (M *m v)^T). {symmetry. apply trmx_mul. }
  rewrite t Heig. apply tr_mul. }
assert (Heigtn : (normR v^T) *m M = lambda *: (normR v^T)). {
  unfold normR. rewrite <- scalemxAl. rewrite Heigt. rewrite !ssmx_mul mulrC //. }
assert (Heign : M *m (normR v^T)^T = lambda *: (normR v^T)^T). {
  rewrite H. assert (t : M^T *m (normR v^T)^T = (normR v^T *m M)^T). {symmetry. apply trmx_mul. }
  rewrite t Heigtn tr_mul //. }
assert (eM : exists (M' : 'M[R]_n), (col_mx (normR v^T) W) *m M *m (col_mx (normR v^T) W)^T = block_mx (lambda%:M : 'M[R]_1) 0 0 M'). {
  rewrite mul_col_mx tr_col_mx mul_col_row. exists (W *m M *m W^T).
  assert (z3 : W *m (normR v^T)^T = 0). {apply (orthvecs_orth oU). }
  assert (z2 : normR v^T *m W^T = 0). {rewrite <- (trmxK (normR v^T)). rewrite <- trmx0. rewrite <- z3. symmetry. apply trmx_mul. }
  assert (eM1 : normR v^T *m M *m (normR v^T)^T = lambda%:M). {
    rewrite Heigtn. rewrite <- scalemxAl. rewrite (normal_to_id (normR_is_normal vtnz)).
    apply scalemx1. }
  assert (eM2 : normR v^T *m M *m W^T = 0). {
    rewrite Heigtn. rewrite <- scalemxAl. rewrite z2. rewrite scalemx_const. rewrite mulr0 //. }
  assert (eM3 : W *m M *m (normR v^T)^T = 0). {
    rewrite <- mulmxA. rewrite Heign. rewrite <- mul_scalar_mx.
    rewrite mulmxA scalar_mxC. rewrite <- mulmxA. rewrite z3. rewrite mulmx0 //. }
  rewrite eM1 eM2 eM3 //. }
destruct eM as [M' eM]. exists M'. exists lambda. split. apply oU. split.
- (*Proving M' is symmetric*)
  assert (sym : symmx (block_mx (lambda%:M : 'M[R]_1) 0 0 M')). {
    rewrite <- eM. unfold symmx. rewrite trmx_mul. rewrite trmxK. rewrite trmx_mul. 
    rewrite <- H. symmetry. apply mulmxA. }
  unfold symmx in sym. rewrite tr_block_mx in sym. apply (eq_block_mx sym).
apply eM.
Qed.
  

(* The spectral theorem for finite-dimensional real symmetric matrices: *)
Theorem spec {n : nat} (M : 'M[R]_n) : symmx M -> 
  exists (U : 'M[R]_n) (D : 'M[R]_n), orthmx U /\ is_diag_mx D /\ M = U^T *m D *m U.
Proof.
intros H. induction n as [|n' IH].
- (*0-dimensional case*) exists 0. exists 0. split.
  + (* orthogonality: *) unfold orthmx. rewrite mul0mx. symmetry. apply flatmx0. split.
  + (* diagonal: *) apply mx0_is_diag.
  + (* product: *) rewrite !mulmx0. apply flatmx0.
- (*inductive case:*) destruct (spec1 H) as [U H']. destruct H' as [M' H'].
  destruct H' as [lambda H']. destruct H' as [oU H']. destruct H' as [H' mult].
  destruct (IH M' H') as [U' IH']. destruct IH' as [D' IH']. destruct IH' as [oU' IH'].
  destruct IH' as [IH' mult']. exists ((one_dirp U') *m U). 
  exists (block_mx (lambda%:M : 'M[R]_1) 0 0 D'). split.
  + (* orthogonality: *) apply orthmx_prod. apply one_dirp_pres_orth. apply oU'. apply oU. split.
  + (* diagonal: *) rewrite (is_diag_block_mx (lambda%:M : 'M[R]_1) 0 0 D').
    rewrite IH'. rewrite scalar_mx_is_diag. 
    assert (z1 : (0 :'rV[R]_n') == 0). {by []. }
    assert (z2 : (0 :'cV[R]_n') == 0). {by []. }
    rewrite z1 z2 //. reflexivity.
  + (* product: *) rewrite mulmxA. rewrite trmx_mul. rewrite one_dirp_tr. 
    assert (t :  U^T *m (one_dirp U'^T) *m (block_mx (lambda%:M : 'M[R]_1) 0 0 D')
          = U^T *m ((one_dirp U'^T) *m (block_mx (lambda%:M : 'M[R]_1) 0 0 D'))). {
      rewrite mulmxA //. } rewrite t.
    assert (t' : U^T *m ((one_dirp U'^T) *m (block_mx (lambda%:M : 'M[R]_1) 0 0 D')) *m one_dirp U' 
          = U^T *m (((one_dirp U'^T) *m (block_mx (lambda%:M : 'M[R]_1) 0 0 D')) *m one_dirp U')). {
      rewrite [in RHS]mulmxA //. } rewrite t'.
    unfold one_dirp. 
    rewrite (block_diag_mulmx U'^T D' (1%:M : 'M[R]_1) (lambda%:M : 'M[R]_1)).
    rewrite mul1mx.
    rewrite (block_diag_mulmx (U'^T *m D') U' (lambda%:M : 'M[R]_1) (1%:M : 'M[R]_1)).
    rewrite mulmx1. rewrite <- mult'.
    assert (t'' : block_mx (lambda%:M : 'M[R]_1) 0 0 M' = U *m M *m U^T). {
      symmetry. apply mult. } rewrite t''.
    rewrite !mulmxA. rewrite (mulmx1C oU) mul1mx.
    rewrite <- mulmxA. rewrite (mulmx1C oU) mulmx1 //.
Qed.




