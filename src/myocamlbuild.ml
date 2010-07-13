open Ocamlbuild_plugin

(* these functions are not really officially exported *)
let run_and_read = Ocamlbuild_pack.My_unix.run_and_read
let blank_sep_strings = Ocamlbuild_pack.Lexers.blank_sep_strings

(* this lists all supported packages *)
let find_packages () =
  blank_sep_strings &
    Lexing.from_string &
      run_and_read "ocamlfind list | cut -d' ' -f1"

(* this is supposed to list available syntaxes, but I don't know how to do it. *)
let find_syntaxes () = ["camlp4o"; "camlp4r"]

(* ocamlfind command *)
let ocamlfind x = S[A"ocamlfind"; x]

let _ = dispatch begin function
   | Before_options ->

       (* override default commands by ocamlfind ones *)
       Options.ocamlc   := ocamlfind & A"ocamlc";
       Options.ocamlopt := ocamlfind & A"ocamlopt";
       Options.ocamldep := ocamlfind & A"ocamldep";
       Options.ocamldoc := ocamlfind & A"ocamldoc";

   | After_rules ->
      (* Compile and link *)
      flag ["link"; "ocaml"; "byte"] (A"-custom");
      dep  ["link"; "ocaml"] ["stub.o"];
      flag ["c"; "compile"] &
        (*S[A"-ccopt"; A"-O3"; A"-ccopt"; A"-Wall"; A"-ccopt"; A"-pg"];*)
        S[ A"-ccopt"; A"-O3";
           A"-ccopt"; A"-Wall";
           A"-ccopt"; A"-ggdb"; ];

      (* When one link an OCaml library/binary/package, one should use -linkpkg *)
      flag ["ocaml"; "link"] & S[A"-linkpkg"; A"-cclib"; A"-llua5.1"];
      flag ["ocaml"; "thread_option"] & A"-thread";

       (* For each ocamlfind package one inject the -package option when
       	* compiling, computing dependencies, generating documentation and
       	* linking. *)
        List.iter
          (
            fun pkg ->
              flag ["ocaml"; "compile";         "pkg_"^pkg] & S[A"-package"; A pkg];
              flag ["ocaml"; "ocamldep";        "pkg_"^pkg] & S[A"-package"; A pkg];
              flag ["ocaml"; "doc";             "pkg_"^pkg] & S[A"-package"; A pkg];
              flag ["ocaml"; "link";            "pkg_"^pkg] & S[A"-package"; A pkg];
              flag ["ocaml"; "infer_interface"; "pkg_"^pkg] & S[A"-package"; A pkg];
          ) (find_packages ());

       (* Like -package but for extensions syntax. Morover -syntax is useless
       	* when linking. *)
        List.iter
        (
          fun syntax ->
            flag ["ocaml"; "compile";  "syntax_"^syntax] & S[A"-syntax"; A syntax];
            flag ["ocaml"; "ocamldep"; "syntax_"^syntax] & S[A"-syntax"; A syntax];
            flag ["ocaml"; "doc";      "syntax_"^syntax] & S[A"-syntax"; A syntax];
        ) (find_syntaxes ());

   | _ -> ()
end
