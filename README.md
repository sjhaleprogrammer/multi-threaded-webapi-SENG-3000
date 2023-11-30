# webapi

multithreaded webapi written in Nim 👑 with HappyX webframework, norm, and norman.

included example migration 

# use requests.http to test routes barebones html template included.


# deps to build/run project
nim 2.0
sqlite 
nimble package manager (nimble package manager will install all other nim libaries stored at ~/.nimble)


# dev shell
"nix-shell -p nim2 nimPackages.nimble sqlite" 

note "nimPackages.nimble" is a unstable package so you must be on the unstable channel


# all these commands need to ran as sudo
"sudo nix-channel --list" checks your current channels
"sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos" replaces current channel with unstable
finally run "sudo nix-channel --update"



# list of useful commands

HttpBeast
"nimble build -d:beast --threads=on --deepcopy:on" to compile the program using beast *recommended*

MicroAsyncHttpServer
"nimble build --threads=on --deepcopy:on" to compile using async server 

Httpx
"nimble build -d:httpx --threads=on --deepcopy:on" to compile using httpx server 


# must have norman in your path to run these commands !!!!!

"export PATH=$PATH:~/.nimble/bin" will add norman to your path 

"norman undo" removes the one mirgration that was already done 

"norman migrate" adds the migration back to the database adding back the values 

"norman generate -m "migration name here" " generates a new migration

more info for norman at https://github.com/moigagoo/norman