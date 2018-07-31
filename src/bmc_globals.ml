open Z3


(* TODO: move to bmc_conf *)

(* Z3 context config *)
let g_z3_ctx_cfg = [ ("model", "true")  (* Generate model *)
                   ; ("proof", "false") (* Disable proof generation *)
                   ]
let g_ctx = mk_context g_z3_ctx_cfg

let g_z3_solver_logic_opt = None        (* Logic used by the solver *)
let g_solver              = Solver.mk_solver g_ctx g_z3_solver_logic_opt

let g_macro_finder = true

let g_bmc_debug = 10
let g_single_threaded = false

let g_bv = false

type bmc_conf = {
  bv_precision    : int;
  max_run_depth   : int;
  sequentialise   : bool;
  concurrent_mode : bool;
}

let (!!) z = !z()

let bmc_conf : (unit -> bmc_conf) ref =
  ref (fun () -> failwith "bmc_conf is undefined")

let set bmc_bvprec bmc_max_depth bmc_seq bmc_conc =
  bmc_conf := fun () ->
  { bv_precision    = bmc_bvprec;
    max_run_depth   = bmc_max_depth;
    sequentialise   = bmc_seq;
    concurrent_mode = bmc_conc;
  }

(* true => use bit vector representation *)

(*
let g_bv_precision = 32

let g_max_run_depth = 3    (* Maximum function call/run depth per call/run *)
let g_sequentialise = false (* Sequentialise Core *)

let g_concurrent_mode = false
*)
