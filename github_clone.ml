(*
  Backup one's public repositories to a directory

  Baris Metin <baris ! metin.org>
*)

open List
open Printf
open Shell
open Json_io
open Json_type.Browse
open Http_client.Convenience

let usage_msg = 
  "\nUsage: github_clone -u USER [-owner] [SYNC_DIRECTORY]\n" ^
  "Backup USER's public github repositories locally.\n" 

let is_owner = ref false
let github_user = ref ""
let sync_dir = ref "."

let optionspeclist = 
  [ 
    ("-owner", Arg.Set (is_owner), "Checkout projects as the owner");
    ("-u", Arg.Set_string (github_user), "Github username");
  ]


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
        
    method url repo = 
      if !is_owner then
        "git@github.com:" ^ user ^ "/" ^ repo ^ ".git"
      else
        "git://github.com/" ^ user ^ "/" ^ repo ^ ".git"

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
      print_endline repo_url;
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



let () = 
  Arg.parse optionspeclist (fun x -> sync_dir := x) usage_msg;
  
  if !github_user = "" then
    begin
      Arg.usage optionspeclist usage_msg;
      exit 1
    end;

  let g = new github !github_user in
  let rec clone_all repos = 
    match repos with
      [] -> ()
    | repo::repos' ->
        begin
          g#clone repo !sync_dir;
          clone_all repos'
        end
  in

  clone_all g#repo_names
