# Copyright (c) 2026 Sławomir Laskowski
# SPDX-License-Identifier: MIT

 git log --pretty=format:'{"message": "%f", "date": "%ad", "commit": "%h"}%n'
  | from json -o
  | update date { |it| $it.date | into datetime }

let yesterday = (date now) - 4day

# $lol | where date > $yesterday | select message commit date

# $table | into value -c [column1, column5]


git for-each-ref --sort=-committerdate refs/heads/ | lines | split column "\t" | update 1 {}

let my = "ok4"

def animals [] {
  do { cd dist; ls } | where name =~ \.js$
    | each { |it| str replace "dist/" "" name }
    | each { |it| str replace .js "" name }
    | get name

}

export def run [script: string@animals] {
  clear
  node $"dist/($script).js"
}

export def type_cmd [cmd: string] {
  osascript -e $'tell application "System Events" to keystroke "($cmd)"'
}


$env.PATH = (
  $env.PATH
  | split row (char esep)
  | append /usr/local/bin
  | append ($env.CARGO_HOME | path join bin)
  | append ($env.HOME | path join .local bin)
  | uniq # filter so the paths are unique
)


use std *
path add /usr/local/bin ($env.CARGO_HOME | path join bin) # etc.

module commands {
  def animals [] {
      ["cat", "dog", "eel" ]
  }

  export def my-command [animal: string@animals] {
      print $animal
  }
}

def greet [name: string] {
  $"hello ($name)"
}


with-env {X: "Y", W: "Z"} { [$env.X $env.W] }

# see https://github.com/nushell/nushell/issues/1616
# fzf through shell history, typing result.
# Requires `xdotool`.
def fzf-history [
	--query (-q): string # Optionally start with given query.
] {
	let cmd = (history | reverse | reduce { $acc + (char nl) + $it } | fzf --prompt "HISTORY> " --query $"($query)")
	xdotool type $cmd
}



def images [] {
  docker image ls --format '{{json .}}' | lines | each {
    |line|
      let id = echo $line | from json | get ID
      docker inspect $id --format='{{json .}}' | from json | update RepoTags {
        |tags| $tags.RepoTags | get 0 -i | default '' | str replace ":latest" ""
      }
  }
}

def containers [] {
  let imgs = images

  docker ps -aq | xargs docker inspect --format='{{json .}}' | from json -o
    | update Image { |e| $imgs | where Id == $e.Image | get 0 -i }
    | update Id { |e| $e.Id | str substring 5..11 }
    | where State.Running == true
    | select Id Name State.Status Image.RepoTags Image.Architecture

}


def monitor [
  --dur(-d): duration = 2sec, # time between retries
  command: closure, # command to run
] {
  loop {
      let till = (date now) + $dur
      clear
      do $command | print
      sleep ($till - (date now))
  }
}


[ '.', '/home', 'MRE'] | all {path exists}
[ '.', '/home', 'MRE'] | any {path exists}


let csv = open --raw "/Users/billy/Downloads/grafik styczeń czerniewice 2025/Arkusz1-Table 1.csv" | from csv --separator ';' --noheaders

$csv | reject column0 | get 2 7 | headers | transpose | skip 2 | rename day shift | where shift !~ ^W

$env.config = {
  keybindings: [
    {
      name: fuzzy_history
      modifier: control
      keycode: char_r
      mode: [emacs, vi_normal, vi_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "let result = (
            history
            | get command
            | uniq
            | reverse
            | str join (char -i 0)
            | fzf --scheme=history
              --read0
              --height=40%
              --bind=ctrl-r:toggle-sort
              --highlight-line
              --query=(commandline | str substring 0..(commandline get-cursor))
              +m
            | complete
          ); if ($result.exit_code == 0) { commandline edit ($result.stdout | str trim) }"
        }
      ]
    }
    {
      name: fuzzy_file_dir_completion
      modifier: control
      keycode: char_t
      mode: [emacs, vi_normal, vi_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "commandline edit --insert (
            fzf --scheme=path
              --read0
              --height=40%
              --reverse
              --walker=file,dir,follow,hidden
              -m
            | lines
            | str join ' '
          )"
        }
      ]
    }
    {
      name: fuzzy_cd
      modifier: control
      keycode: char_z
      mode: [emacs, vi_normal, vi_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "cd (
            fzf --scheme=path
              --read0
              --height=40%
              --reverse
              --walker=dir,follow,hidden
              +m
          )"
        }
      ]
    }
  ]
}



def main [x: int] {
  $x + 10
}

let f: glob = "~/aaa"
ls $f                 # tilde will be expanded

# 0.92.0 (47x faster!)
1..1000 | each { timeit { nu-python 1 foo } } | math avg
# 871µs 410ns

# Get the sum of numbers from 1 to 100, but also save those numbers to a text file
seq 1 100 | tee { save numbers.txt } | math sum
# The exact opposite: keep the numbers, but save the sum to a file
seq 1 100 | tee { math sum | save sum.txt }
# Run an external command, and save a copy of its log output on stderr
do { cargo run } | tee --stderr { save err.txt }
# Filter the log output before saving it
do { cargo run } | tee --stderr { lines | find WARN | save warnings.txt }

# ls | select ...$cols
#
ls | tee { save ls.json }


ssh -p 2948 admin@192.168.50.1

> [[foo bar] [baz quux]] | into record
