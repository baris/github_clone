(* ocamlfind opt -package "netclient json-wheel str shell" -linkpkg github.ml -o github *)

open List
open Printf
open Shell
open Json_io
open Json_type.Browse
open Http_client.Convenience


(* get name from json object *)
let get_field_from json name =
  hd
    (map (fun (x,y) -> string y)
       (filter (fun (x,y) -> x = name) (objekt json)))


class github user =
  object (self)
    val api_url = "http://github.com/api/v2/json"
    val user = user

    method get url = http_get url
        
    method user =
      let user_url = String.concat "/" [api_url; "user/show"; user] in
      self#get user_url

    method repos =
      let repos_url = String.concat "/" [api_url; "repos/show"; user] in
      self#get repos_url
        
    method url repo = "git@github.com:" ^ user ^ "/" ^ repo ^ ".git"

    method repo_names =
      (* return public repositories of a user as a list *)
      let json_obj = json_of_string self#repos in
      let tbl = make_table (objekt json_obj) in
      let lst = array (field tbl "repositories") in
      let rec names lst = 
        match lst with
          [] -> []
        | x::lst' -> (get_field_from x "name") :: (names lst') in
      names lst

    method clone repo target_dir =
      let target_workdir = String.concat "/" [target_dir;repo]
      and repo_url = self#url repo in
      print_endline ("Working on " ^ target_workdir);
      if Sys.file_exists target_workdir && Sys.is_directory target_workdir then
        begin
          let cur_dir = Sys.getcwd () in
          Sys.chdir target_workdir;
          call [ cmd "git" ["pull"] ];
          Sys.chdir cur_dir
        end
      else
        begin
          call [ cmd "git" ["clone"; repo_url; target_workdir] ]
        end
        
  end


let usage () =
  printf "%s USER TARGET_DIR\n" Sys.argv.(0)


let () = 
  if Array.length Sys.argv <> 3 then
    begin
      usage ();
      exit 1
    end;
      
  let user = Sys.argv.(1) in
  let target_dir = Sys.argv.(2) in

  let g = new github user in
  let rec clone_all repos = 
    match repos with
      [] -> ()
    | repo::repos' ->
        begin
          g#clone repo target_dir;
          clone_all repos'
        end
  in

  clone_all g#repo_names
