type state_entry = {
    loc_e : Pp.document option;
    loc_v : Pp.document option;
    state : Pp.document option;
  }

type term_entry = {
    term : Pp.document;
    value : Pp.document;
  }

type predicate_clause_entry = {
    cond : Pp.document;
    clause : Pp.document;
  }

type resource_entry = {
    res : Pp.document;
    res_span : Pp.document;
  }

<<<<<<< HEAD
=======
(* type intra_label_trace_item_report = {  *)
(*   stmt : Pp.document;  *)
(*   within : Pp.document list  *)
(* } *)
(* type per_label_trace_report = {  *)
(*   label : Pp.document;  *)
(*   trace : intra_label_trace_item_report list; *)
(* } *)
(* type trace_report = per_label_trace_report list *)

>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93
type where_report = {
    fnction: string option;
    section: string option;
    loc_cartesian: ((int * int) * (int * int)) option;
    loc_head: string;
    (* loc_pos: string; *)
  }

type state_report = {
    where: where_report;
    (* variables : var_entry list; *)
    resources : (Pp.document list * Pp.document list);
    constraints: (Pp.document list * Pp.document list); (* interesting/uninteresting *)
    terms : (term_entry list * term_entry list);
  }

type report = {
    trace : state_report list;
    requested : Pp.document option;
    unproven : (Pp.document (* * Pp.document *)) option;
    predicate_hints : predicate_clause_entry list;
  }


let list elements = String.concat "" elements
let enclose tag what = "<"^tag^">" ^ what ^ "</"^tag^">"
(* let html elements = enclose "html" (list elements) *)
(* let head = enclose "head" *)
(* let style = enclose "style" *)
let _link ~url ~text = "<a href=\""^url^"\">"^text^"</a>"
let div ?clss ?id elements =
  let clss = match clss with
    | Some clss -> " class=\""^clss^"\""
    | None -> ""
  in
  let id = match id with
    | Some id -> " id=\""^id^"\""
    | None -> ""
  in
  let opent = "<div" ^ clss ^ id ^ ">" in
  let closet = "</div>" in
  opent ^ (list elements) ^ closet
(* let pre code = enclose "pre" code *)
<<<<<<< HEAD
(* let body elements = enclose "body" (list elements) *)
=======
let body elements = enclose "body" (list elements)
>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93
let h i title body = list [enclose ("h"^string_of_int i) title; body]
let table_row cols = enclose "tr" (list (List.map (enclose "td") cols))
let table_head_row cols = enclose "tr" (list (List.map (enclose "th") cols))
let table_head cols = enclose "thead" (table_head_row cols)
let table_body rows = enclose "tbody" (list (List.map table_row rows))
let table head rows = enclose "table" (list [table_head head; table_body rows])
let table_without_head rows = enclose "table" (list [table_body rows])
let details summary more = enclose "details" (list [enclose "summary" summary; more])
let oguard o f = match o with None -> "" | Some x -> f x
let lguard l f = match l with [] -> "" | _ -> f l


(* let make_requested requested =  *)
(*   oguard requested (fun re -> *)
(*     h 1 "Requested resource" ( *)
(*       table ["requested"; "byte span"] *)
(*         [[Pp.plain re.res; Pp.plain re.res_span]] *)
(*     ) *)
(*   ) *)

let cartesian_to_string = function
  | None -> ""
  | Some ((start_line, start_col), (end_line, end_col)) ->
      Printf.sprintf "%d:%d-%d:%d" start_line start_col end_line end_col

let make_where where =

  let or_empty = function
    | Some s -> s
    | None -> ""
  in

  table ["function"; "section"; "location"]
<<<<<<< HEAD
    [[div ~clss:"loc_function" [or_empty where.fnction];
      div ~clss:"loc_section" [or_empty where.section];
      div ~clss:"loc" [cartesian_to_string where.loc_cartesian];
=======
    [[where.fnction;
      where.section;
      div ~clss:"loc" [if is_javascript then cartesian_to_string where.loc_cartesian else where.loc_head];
>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93
      (* pre (where.loc_pos) *)
    ]]

let make_requested requested =
  oguard requested (fun re ->
    h 1 "Requested resource" (
      table_without_head (* ["requested"; (\* "byte span" *\)] *)
        [[Pp.plain re; (* Pp.plain re.res_span *)]]
    )
  )

let make_unproven unproven =
  oguard unproven (fun c ->
    h 1 "Unproven constraint (simplified)" (
      table_without_head (* ["constraint"; "simplified constraint"] *)
        [[Pp.plain c; (* Pp.plain (snd c) *)]]
    )
  )

let make_predicate_hints predicate_hints =
  lguard predicate_hints (fun predicate_hints ->
    h 1 "Possibly relevant predicate clauses" (
      table ["condition"; "clause"]
        (List.map (fun pce -> [Pp.plain pce.cond; Pp.plain pce.clause]) predicate_hints)
    )
  )

(* let make_resources resources =  *)
(*   h 1 "Available resources" ( *)
(*     match resources with *)
(*     | [] -> "(no available resources)" *)
(*     | _ -> *)
(*       table ["resource"; "byte span and match"] *)
(*         (List.map (fun re -> [Pp.plain re.res; Pp.plain re.res_span]) resources) *)
(*   ) *)




let interesting_uninteresting
      (interesting_table, interesting_data)
      (uninteresting_table, uninteresting_data)
  =
  match interesting_data, uninteresting_data with
  | [], [] -> "(none)"
  | _ , [] -> interesting_table
  | [], _  -> details "more" uninteresting_table
  | _ , _  -> interesting_table ^ details "more" uninteresting_table


let make_resources (interesting, uninteresting) =
  let make = List.map (fun re -> [Pp.plain re; (* Pp.plain re.res_span *)]) in
  let interesting_table = table_without_head (make interesting) in
  let uninteresting_table = table_without_head (make uninteresting) in
  h 1 "Available resources" (
      interesting_uninteresting
        (interesting_table, interesting)
        (uninteresting_table, uninteresting)
  )



let make_terms (interesting, uninteresting) =
  let make = List.map (fun v -> [Pp.plain v.term; Pp.plain v.value]) in
<<<<<<< HEAD
  let interesting_table = table ["term"; "value"] (make interesting) in
  let uninteresting_table = table ["term"; "value"] (make uninteresting) in
  h 1 "Terms" 
    (interesting_uninteresting 
       (interesting_table, interesting) 
=======
  let interesting_table = table ["variable"; "value"] (make interesting) in
  let uninteresting_table = table ["variable"; "value"] (make uninteresting) in
  h 1 "Terms"
    (interesting_uninteresting
       (interesting_table, interesting)
>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93
       (uninteresting_table, uninteresting))

let make_constraints (interesting, uninteresting) =
  let make = List.map (fun c -> [Pp.plain c]) in
  let interesting_table = table_without_head (make interesting) in
  let uninteresting_table = table_without_head (make uninteresting) in
  h 1 "Constraints"
    (interesting_uninteresting
       (interesting_table, interesting)
       (uninteresting_table, uninteresting))





<<<<<<< HEAD
=======
(* Doing multiple 'pages' within one html file based on this scheme:
   https://www.w3.org/Style/Examples/007/target.en.html *)


let make_state (report: state_report) requested unproven predicate_hints i total =
  let links =
    let first =
      if i = 0
      then div ~clss:"inactive_button" ["first"]
      else div ~clss:"button" [(link ~url:("#"^page_name 0) ~text:"first")]
    in
    let prev =
      if i = 0
      then div ~clss:"inactive_button" ["prev"]
      else div ~clss:"button" [(link ~url:("#"^page_name (i-1)) ~text:"prev")]
    in
    let next =
      if i = total - 1
      then div ~clss:"inactive_button" ["next"]
      else div ~clss:"button" [(link ~url:("#"^page_name (i+1)) ~text:"next")]
    in
    let last =
      if i = total - 1
      then div ~clss:"inactive_button" ["last"]
      else div ~clss:"button" [(link ~url:("#"^page_name (total - 1)) ~text:"last")]
    in
    [ first; prev; next; last ]
  in
  div ~clss:"page" ~id:(page_name i) [
      div ~clss:"pagelinks" links;
      div ~clss:"pagecontent" [
        make_where report.where;
        make_requested requested;
        make_unproven unproven;
        make_predicate_hints predicate_hints;
        make_resources report.resources;
        make_terms report.terms;
        make_constraints report.constraints;
      ]
    ]


let make filename (report : report) =

  let channel = open_out filename in

  let total = List.length report.trace in
  assert (total > 0);

  let contents =
    let pages =
      List.mapi (fun i state ->
          make_state
            state
            report.requested
            report.unproven
            report.predicate_hints
            i total
        ) report.trace
    in
    html [
      head (style Style.style);
      body [
          div ~id:"pages" pages
        ]
    ]
  in

  let () = Printf.fprintf channel "%s" contents in

  close_out channel;

  filename ^ "#" ^ page_name (total-1)
>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93


let css = {|
html {
  font-family: sans-serif;
  font-size: 11pt
}

body {
  padding: 0;
  margin: 0;
  overflow: hidden;
}

table {
  width: 100%;
  border: 1px solid;
  border-collapse: collapse;
}

h1 {
  font-size: 11pt;
  margin-top: 16pt;
}

tr {
  padding: 0;
  margin: 0;
}

.hidden {
  display: none;
}

th, td {
  text-align: left;
  vertical-align: top;
  border-left: 1px solid;
  border-right: 1px solid;
  padding-left: 5px;
  padding-right: 5px;
  padding-top: 3px;
  padding-bottom: 3px;
}

th {
  padding-top: 5px;
  padding-bottom: 5px;
}

th {
  font-weight: normal;
  font-style: italic;
}

#root {
  display: flex;
  height: 100vh;
  margin: 0;
  padding: 0;
}

.menu {
  font-size: 15px;
  margin: 0px;
  padding: 0px;
  vertical-align: middle;
}

.menu ul {
  list-style-type: none;
  display: inline;
  padding: 0;
  margin: 0;
}

.menu li {
  padding: 0px;
  margin: 0px;
  float: left;
}

.menu button {
  all: unset;
  padding: 7px;
}

#pageinfo {
  padding: 7px;
  display: inline-block;
}

#sectioninfo {
  padding: 7px;
  display: inline-block;
}

#cn_state {
  width: 50%;
  align-content: flex-start;
  display: grid;
}

#pages {
  padding: 10px;
  overflow-y:scroll;
}

#cn_code_display {
  width: 50%;
  display: grid;
  align-content: flex-start;
}

#cn_code {
  overflow-y:scroll;
  /* padding: 5px; */
  font-family: monospace;
  white-space-collapse: preserve;
  /* text-wrap: nowrap; */
  white-space: pre;
}

.nb {
  padding-left: 5px;
  /* TODO this will clip if there are more than 999 lines */
  width: 35px;
}

.hl {
    display: inline;
}

.line {
  padding-left: 8px;
  /* overflow:scroll; */
}

@media (prefers-color-scheme: dark) {

  html {
    background-color: black;
    color: lightgray;
  }

  table, th, td {
    border-color: #303030;
  }

  tr {
    background-color: #181818;
  }

  th {
    background-color: #252525;
    border-bottom: 1px solid #303030;
  }

  tr:hover {
    background-color: #101044;
  }

  .hl {
    background-color: #2727a6;
  }

  .menu {
    background-color: #CCCCCC;
    color: black;
  }

  .menu button:hover {
    background-color: #AAAAAA;
  }

  #cn_code {
    background-color: rgb(30, 30, 30);
  }

  .nb {
    width: 35px;
    color: rgb(150, 150, 150);
    background-color: rgb(50, 50, 50);
  }
}

@media (prefers-color-scheme: light) {

  html {
    background-color: white;
    color: black;
  }

  table, th, td {
    border-color: #E9E9E9;
  }

  tr {
    background-color: #F8F8F8;
  }

  th {
    background-color: #F0F0F0;
    border-bottom: 1px solid #E9E9E9;
  }

  tr:hover {
    background-color: #E2F0FF;
  }

  .hl {
    background-color: #b4d8fd;
  }

  .menu {
    background-color: #333333;
    color: white;
  }

  .menu button:hover {
    background-color: #555555;
  }

  #cn_code {
    background-color: rgb(245, 245, 245);
  }

  .nb {
    width: 35px;
    color: rgb(150, 150, 150);
    background-color: rgb(230, 230, 230);
  }
}
|}

let script = {|
var current_page = 1
const menu = document.getElementById("menu1").children
const pageinfo = document.getElementById("pageinfo")
const pages = document.getElementById("pages").children
const cn_code = document.getElementById("cn_code")
const n_pages = pages.length


function clear_highlight() {
  Array.from(document.getElementById("cn_code").children).forEach((e) => {
    div = e.children[1]
    div.replaceChildren(div.textContent)
  })
}

function highlight(line, start_col, end_col) {
  // console.log(`HIGHLIGHT(${line}, ${start_col}, ${end_col})`)
  if (end_col <= start_col) {
    end_col = start_col+1
  }
  Array.from(cn_code.children).forEach((e, n) => {
    div = e.children[1]
    if (n != line-1) {
      div.replaceChildren(div.textContent)
    } else {
      str = div.textContent
      before = str.substring(0, start_col-1)
      hl = document.createElement("span")
      hl.classList.add("hl")
      hl.textContent = str.substring(start_col-1,end_col-1)
      after = str.substring(end_col-1)
      div.replaceChildren(before,hl,after)
      cn_code.scrollTop = div.offsetTop
    }
  })
}

function multiline_highlight(start_line, start_col, end_line, end_col) {
  Array.from(cn_code.children).forEach((e, n) => {
    div = e.children[1]
    if (n < start_line || end_line < n) {
      div.replaceChildren(div.textContent)
    } else {
      str = div.textContent
      if (n == start_line) {
        cn_code.scrollTop = div.offsetTop
      }
      hl = document.createElement("span")
      hl.classList.add("hl")
      // TODO: probably could be written nicer
      if (start_line == end_line) {
        before = str.substring(0, start_col)
        hl.textContent = str.substring(start_col,end_col)
        after = str.substring(end_col)
        div.replaceChildren(before,hl,after)
      } else if (n == start_line) {
        before = str.substring(0, start_col)
        hl.textContent = str.substring(start_col)
        div.replaceChildren(before,hl)
      } else if (n == end_line) {
        hl.textContent = str.substring(0,end_col)
        after = str.substring(end_col)
        div.replaceChildren(hl,after)
      } else {
        hl.textContent = str
        div.replaceChildren(hl)
      }
    }
  })
}

// function decode_loc(n) {
//   loc = pages[n-1].getElementsByClassName("loc")[0].textContent
//   console.log("DECODING ==> ", loc)
//   if (loc == "") {
//     // console.log("NO LOC")
//     clear_highlight()
//   } else {
//     xs = loc.split(" ")[1].split(":")
//     line = xs[1]
//     col = parseInt(xs[2])
//     // console.log(`LOC ==> line: ${line} -- col: ${col}`)
//     highlight(line, col, col+1)
//   }
// }

function decode_loc(n) {
  loc = pages[n-1].getElementsByClassName("loc")[0].textContent
  fnction = pages[n-1].getElementsByClassName("loc_function")[0].textContent
  section = pages[n-1].getElementsByClassName("loc_section")[0].textContent
  if (loc == "") {
    clear_highlight()
  } else {
    pair = loc.split("-")
    start = pair[0].split(":")
    end = pair[1].split(":")
    multiline_highlight(start[0], start[1], end[0], end[1])
  }
  if (fnction == "") {
    sectioninfo.textContent = "(none)"
  }
  else if (section == "") {
    sectioninfo.textContent = fnction
  }
  else {
    sectioninfo.textContent = `${fnction}  >  ${section}`
  }
}

function goto_page(n) {
  if (0 < n && n <= n_pages ) {
    // console.log(`GOTO_PAGE(${n} ==> current: ${current_page})`)
    decode_loc(n)
    pages[current_page - 1].style.display = "none"
    pages[n-1].style.display = "block"
    current_page = n

    pageinfo.textContent = `[${current_page} / ${n_pages}]`
    menu[0].disabled = false
    menu[1].disabled = false
    menu[2].disabled = false
    menu[3].disabled = false
    if (current_page == 1) {
      menu[0].disabled = true
      menu[1].disabled = true
    } else if (current_page == n_pages) {
      menu[2].disabled = true
      menu[3].disabled = true
    }
  }
}

function goto_prev() {
  goto_page(current_page-1)
}

function goto_next() {
  goto_page(current_page+1)
}

function create_line(n, str) {
  nb_div = document.createElement("div")
  str_div = document.createElement("div")
  nb_div.textContent = n
  nb_div.classList.add("nb")
  str_div.textContent = str
  str_div.classList.add("line")
  ret = document.createElement("div")
  ret.style.display = "flex"
  ret.replaceChildren(nb_div, str_div)
  return ret
}

function init() {
  lines = cn_code.textContent.split("\n")
  lines.forEach((e, n) => {
    if (n == 0) {
      cn_code.replaceChildren(create_line(1, e))
    } else {
      cn_code.appendChild(create_line(n+1, e))
    }
  })

  goto_page(1)

  Array.from(pages).forEach((e, i) => {
    if (i != 0) {
      e.style.display = "none"
    }
  })
}

init()
|}


let make_state (report: state_report) requested unproven predicate_hints =
  div ~clss:"page" [
    div ~clss:"hidden" [make_where report.where];
    make_requested requested;
    make_unproven unproven;
    make_predicate_hints predicate_hints;
    make_resources report.resources;
    make_terms report.terms;
    make_constraints report.constraints;
  ]


let mk_html ~title ~pages ~file_content ~n_pages= {|
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>|} ^ title ^ {|</title>
<style>|} ^ css ^ {|</style>
</head>

<div id="root">
  <div id="cn_state">
  <div class="menu" id="menu1">
    <ul>
    <li><button onclick="goto_page(1)"/>first</button></li>
    <li><button onclick="goto_prev()"/>prev</button></li>
    <li><button onclick="goto_next()"/>next</button></li>
    <li><button onclick="goto_page(|} ^ string_of_int n_pages ^ {|)"/>last</button></li>
    </ul>
    <div id="pageinfo"></div>
  </div>
  |} ^ pages ^ {|
  </div>
<div id="cn_code_display">
<div class="menu" id="menu2">
  <div id="sectioninfo"></div>
</div>
|} ^ file_content ^ {|
</div>
</div>

<script defer>|} ^ script ^ {|</script>
</html>
|}

let read_file filename =
  try
    let ic = open_in filename in
    Some (In_channel.input_all ic)
  with
    | _ -> None

let make filename source_filename_opt (report: report) =
  let n_pages = List.length report.trace in
  assert (n_pages > 0);

  let _menu = div ~id:"menu"
    [ {|<input type="button" value="first" onclick="goto_page(|} ^ string_of_int 1 ^ {|)"/>|}
    ; {|<input type="button" value="prev" onclick="goto_prev()"/>|}
    ; {|<input type="button" value="next" onclick="goto_next()"/>|}
    ; {|<input type="button" value="last" onclick="goto_page(|} ^ string_of_int n_pages ^ {|)"/>|} ] in

  let pages = div ~id:"pages" begin
    List.map (fun state ->
<<<<<<< HEAD
      make_state
=======
      make_state2
>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93
        state
        report.requested
        report.unproven
        report.predicate_hints
    ) report.trace
  end in

  let file_content = match Option.bind source_filename_opt read_file with
    | None -> "NO FILE CONTENT FOUND"
    | Some str -> str in
  let oc = open_out filename in
  output_string oc begin
    mk_html ~title:"CN state explorer"
      ~pages
      ~file_content:(div ~id:"cn_code" [file_content])
      ~n_pages
  end;
  close_out oc;
  filename



<<<<<<< HEAD
=======

type column = {
    classes : string list;
    content : string;
    colspan : int
  }
type row = {
    header : bool;
    classes : string list;
    columns : column list
  }


type table = {
    rows : row list;
    column_info : string list
  }

type element =
  | H of int * string
  | P of string
  | UL of element list
  | Details of { summary : string; contents : element }
  | Table of table

type html = {style : string; body : element list}

let classes = function
  | [] -> ""
  | cs -> "class=\""^String.concat " " cs^"\""

let column header {classes = cs; content; colspan} =
  let tag = if header then "th" else "td" in
  "<"^tag^" "^classes cs^" colspan=\"" ^ string_of_int colspan ^ "\">" ^
    content ^
  "</"^tag^">"

let row {header; classes = cs; columns} =
  let content =
    "<tr "^classes cs^">" ^
      String.concat "" (List.map (column header) columns) ^
    "</tr>"
  in
  if header then "<thead>"^content^"</thead>" else content

let column_info column_class =
  "<col class = \""^column_class^"\">"

let table {rows; column_info = ci} =
  "<table>" ^
    String.concat "" (List.map row rows) ^
  "</table>"

let p text =
  "<p>" ^
    text ^
  "</p>"

let h i text =
  "<h"^string_of_int i^">" ^
  text ^
  "</h"^string_of_int i^">"

let ul l =
  "<ul>" ^
  String.concat "" (List.map (fun i -> "<li>" ^ i ^ "</li>") l) ^
  "</ul>"

let details summary contents =
  "<details>" ^
  "<summary>" ^ summary ^ "</summary>" ^
  contents

let rec element = function
  | H (i,text) -> h i text
  | P text-> p text
  | Details { summary; contents } -> details summary (element contents)
  | Table tablecontent -> table tablecontent



let to_html report =

  let sdoc doc = Pp.plain doc in

  (* let o_sdoc o_doc =  *)
  (*   match o_doc with *)
  (*   | Some doc -> sdoc doc *)
  (*   | None -> "" *)
  (* in *)

  (* let state_entry {loc_e; loc_v; state} = *)
  (*   { header = false; *)
  (*     classes = ["memory_entry"]; *)
  (*     columns = [ *)
  (*         { classes = ["loc_e"]; content = o_sdoc loc_e; colspan = 1}; *)
  (*         { classes = ["loc_v"]; content = o_sdoc loc_v; colspan = 1}; *)
  (*         { classes = ["state"]; content = o_sdoc state; colspan = 1}; *)
  (*       ] *)
  (*   } *)
  (* in *)

  let variable_entry {var; value} =
    { header = false;
      classes = ["variable_entry"];
      columns = [
          { classes = ["expression"]; content = sdoc var; colspan = 1 };
          { classes = ["value"]; content = sdoc value; colspan = 2 };
        ]
    }
  in

  let predicate_info_entry {cond; clause} =
    { header = false;
      classes = ["predicate_info_entry"];
      columns = [
          { classes = ["condition"]; content = sdoc cond; colspan = 1 };
          { classes = ["clause"]; content = sdoc clause; colspan = 2 };
        ]
    }
  in

  let resource_entry {res; res_span} =
    { header = false;
      classes = ["resource entry"];
      columns = [
          { classes = ["res"]; content = sdoc res; colspan = 2};
          { classes = ["span"]; content = sdoc res_span; colspan = 1};
        ]
    }
  in


  let full_row_entry nm doc =
    { header = false;
      classes = [nm ^ "_entry"];
      columns = [
          { classes = [nm]; content = sdoc doc; colspan = 3 };
        ]
    }
  in

  let constraint_entry = full_row_entry "constraint" in
  let location_entry = full_row_entry "location" in
  let trace_item_entry = full_row_entry "trace_item" in

  let header hds =
    let columns =
      List.map (fun (name, colspan) ->
          {classes = [];
           content = name;
           colspan = colspan}
        ) hds
    in
    { header = true;
      columns;
      classes = ["table_header"]}
  in

  let opt_header xs hds = if List.length xs = 0
    then [] else [header hds] in


  let table =
    { column_info = ["column1"; "column2"; "column3"];
      rows = (
        (* header [("pointer",1); ("addr",1); ("state",1)] :: *)
        (* List.map state_entry report.memory @ *)
        opt_header report.location_trace [("path to error",3)] @
        make_trace report.trace
        @
        opt_header report.requested [("requested resource", 2); ("byte span", 1)] @
        List.map resource_entry report.requested
        @
        opt_header report.unproven [("unproven constraint", 3)] @
        List.map constraint_entry report.unproven
        @
        opt_header report.predicate_hints [("possibly relevant predicate clauses", 3)] @
        List.map predicate_info_entry report.predicate_hints
        @
        opt_header report.resources [("available resources", 2); ("byte span and match", 1)] @
        List.map resource_entry report.resources
        @
        header [("expression",1); ("value",2)] ::
        List.map variable_entry report.variables
        @
        header [("constraints",3)] ::
        List.map constraint_entry report.constraints
    )}
  in

  let body = [

      Table table
    ]
  in

  { style = Style.style; body }


let print_report report = html (to_html report)

*)
>>>>>>> 859b4d7b6db6a6ff3877c39c7f0b83f7dda60f93
