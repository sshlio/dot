# Copyright (c) 2026 Sławomir Laskowski
# SPDX-License-Identifier: MIT

source ~/.config/nushell/boot.nu

$env.DOCKER_BUILDKIT_PROGRESS = "plain"

def in [path, what: closure] {
  do { cd $path; do $what }
}

def get-env [
  name: string,
  default: closure
] {
  if ($env | get -o $name | is-empty) {
    do $default
  } else {
    $env | get $name
  }
}

def color-file [ft: string, code: string] {
  let fl = (in /tmp { mktemp --suffix $".($ft)"})

  $code | save --append $fl

  bat -l $ft --color always $fl
}

def hist [q = ""] {

  mut base = history | where cwd == (pwd)
    | select start_timestamp command
    | rename time cmd
    | where cmd !~ "^hist( |$)"

  if $q == "" {
    $base = $base | last 60
  } else {
    $base = $base | where cmd =~ $q | uniq-by cmd
  }

  $base | update time { $in | into datetime } | update cmd { color-file sh $in }
}

def ls-size [dir] {
  ls ($dir | path expand) | update size { |it| du $it.name | get apparent | get 0 -o | default $it.size }
    | sort-by size | reverse
    | update name { basename $in }
}

def docker-df [] {
  docker system df | from ssv | update SIZE { $in | into filesize } | sort-by SIZE | reverse
}

def reveal [path] {
  ^open -R $path
}

def rv [path] {
  app Finder
  ^open -R ($path | path expand);
}

def --wrapped opn [...args] {
  /usr/bin/open ...$args
}


def pull [] {
  git pull

  # Fetch changes from remote repository
  git fetch origin $env.MAIN_BRANCH

  # Merge the changes to your local main branch
  git branch -f $env.MAIN_BRANCH $"origin/($env.MAIN_BRANCH)"

  git pull origin $env.MAIN_BRANCH

  git push
}

def branch [] {
  return $"(git rev-parse --abbrev-ref HEAD)"
}

def color --wrapped [colred, ...msg] {
  return $"(ansi $colred)($msg | str join ' ')(ansi reset)"
}

def colorp --wrapped [colred, ...msg] {
  print $"(ansi $colred)($msg | str join ' ')(ansi reset)"
}

def nb [branch] {
  try {
    git checkout $branch
  } catch {
    git checkout -b $branch
    git push --set-upstream origin $branch
  }
}

def mn [] {
  git checkout $env.MAIN_BRANCH
  git pull
}

def ghb [] {
  let repoName = get-env GH_REPO { basename (git rev-parse --show-toplevel) }

  let repoUrl = $"https://github.com/($env.GH_ROOT)/($repoName)"
  let currentBranch = (git branch --show-current)

  $repoUrl

  if ($currentBranch == $env.MAIN_BRANCH) {
    ^open $"($repoUrl)/commits/($currentBranch)"
  } else {
    ^open $"($repoUrl)/compare/($currentBranch)"
  }
}

def load-dotenv-file [file: string] {
  if not ($file | path exists) {
    return {}
  }

  # open $file | lines
  #   | split column '#'
  #   | get column1
  #   # | filter {($in | str length) > 0}
  #   | parse "{key}={value}"
  #   | transpose -r -d
  #   | update value {str trim -c '"'}

  {}
}

def load-dotenv --env [file: string] {
  let envs = (load-dotenv-file $file)

  load-env $envs
}

def update-dotenv [--file: string, envs] {
  let finalObj = (load-dotenv-file $file) | merge $envs

  $finalObj | transpose name value | each { $"($in.name)=($in.value)" } | str join "\n" | save -f $file

  $finalObj
}

def ucfirst [s] {
  let first = ($s | str substring 0..0 | str upcase)
  let rest = ($s | str substring 1..-1)
  $first + $rest
}

def whatever [command: closure] {
  try {
    do $command
    return 0
  } catch { |err| return 1 }
}

def watching [command: closure] {
  while true {
    let out = (do $command)
    clear
    print $out
    sleep 1sec
  }
}

def project_desired [] {
  let proj = (open /tmp/desired_project)

  project $proj
}

def dot [] {
  p Dotfiles
}


def curl_paste [label = ""] {
  mut curlCode = (pbpaste)

  $curlCode = $curlCode | str replace -r -a " \\\\\\n" "\n  "
   | str replace -r -a "^curl -i" "curl"
   | str replace -r -a "^curl" "  curl -i --no-progress-meter"

  $curlCode = $"\(\n($curlCode)\n\)"

  mkdir _billy/scratch

  let d = date now | format date "%Y-%m-%d_%H-%M"
  let path = $"_billy/scratch/curl_($d)_($label).nu"

  $curlCode | save -f $path

  $"nu ($path)" | pbcopy
}


def c [...$msg] {
  git add .
  git commit -m $"($msg | str join ' ')"
  git push
}

def cln [] {
  tmux clear-history;
  clear;
  tmux clear-history;
}

def glog [branch?] {
  print ""
  colorp xterm_fuchsia "------------------"
  print ""
  git log --reverse -n 10 --format=format:'%C(bold blue)%h%C(reset) %C(bold green)(%ar)%C(reset) %C(bold magenta)— %ae%C(reset) %C(bold yellow)%d%C(reset) %n''%C(white)%s%C(reset) %n' ($branch | default "HEAD")
  print ""
  colorp xterm_fuchsia "------------------"
  print ""
}

def graphg [] {
  git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''%C(white)%s%C(reset) %C(bold white)— %an%C(reset)' --abbrev-commit --all
}

def ps-tree [pid: number] {
  mut proceses = ps | where pid == $pid
  mut tab = $proceses


  loop {
    if ($proceses | length) < 1 {
      break
    }

    if ($proceses | get 0 | get ppid) < 2 {
      break
    }
    let ppid = $proceses | get 0 | get ppid
    $proceses = ps | where pid == $ppid

    print $ppid
    print $proceses

    $tab = $proceses | append $tab
  }


  $tab
}

def jobs [] {
  pueue status --json | from json | get tasks | values | insert stat { $in.status | columns | get 0 }
    | insert cmd { $in.command | split row " " | get 0 | path basename }
    | insert start {
      let start = $in.status | values | get 0 | get start?

      if $start == null { return "-" }
      $start | into datetime
    }
    | insert dur {
      let stop = $in.status | values | get 0 | get end?

      if $stop == null { return "-" }

      colored_raw xterm_darkslategray2 ((($stop | into datetime) - $in.start) | format duration min)
    }
    | select id label stat cmd start dur
    | reverse
}

def keyval [key, val?] {
  mkdir _billy/var/keyval
  let keyvalPath = $"_billy/var/keyval/($key).json"

  if ($val == null) {
    let wrapped = open_safe $keyvalPath

    $wrapped | get value?
  } else {
    ({ value: $val }) | to json | save -f $keyvalPath
  }
}

def open_safe [path] {
  if ($path | path exists) {
    open ($path | path expand)
  }
}

def green [value] {
  echo $'(ansi xterm_yellow2)($value)(ansi reset)'
}

def colored [color, value] {
  print $'(ansi $color)($value)(ansi reset)'
}

def colored_raw [color, value] {
  $'(ansi $color)($value)(ansi reset)'
}

def random-hash [l = 5] {
  random chars -l 32 | str replace -a " " "" | str substring 0..$l | str downcase
}

def pqueue_spawn [] {
  let pidfile = "~/Library/Application Support/pueue/pueue.pid";
  let pid = (open_safe $pidfile | into int)

  if ((ps | where pid == $pid | length) == 0) {
    pueued -d
  }
}


def ln_conf [_path, dest?: string] {
  let home = ("~" | path expand)

  let distPath = ($dest | default "~/.config"| path expand)
  let sourncPath = $"("~" | path expand)/p/Dotfiles/($_path)" | path expand

  whatever { ln -s $sourncPath $distPath }
}

def ln_conf_all [] {
  ln_conf kitty
  ln_conf nushell
  ln_conf nvim_pure
  ln_conf phoenix
  ln_conf dist
  ln_conf nvim
  ln_conf kitty
  ln_conf vim
  ln_conf bin
  ln_conf dist
  ln_conf karabiner
  ln_conf ghostty
  ln_conf loader.js
  ln_conf raycast/scripts
  ln_conf yazi
  ln_conf hammerspoon ~/.hammerspoon
  ln_conf .gitignore
  ln_conf tmux.conf
  ln_conf term.tmux.conf
  ln_conf tmux_session

  ln_conf .claude/settings.local.json
}

def reopen_pheanix [] {
  whatever { killall Phoenix }
  opn /Applications/Phoenix.app/
}

def print_current_env [] {
  let current_date = (date now | format date "%Y-%m-%d")
  let commit_info = (git log --pretty=format:"%h :: %s" -n 1)

  colored xterm_orchid $" ($commit_info)"
  colored xterm_greenyellow $" (date now | format date '%Y-%m-%d %H:%M:%S')"
  colored xterm_orchid $env.AWS_PROFILE
}

def notifying [--desc: string, msg, what: closure] {
  let res = whatever $what

  let des = $desc | default $"Returned with code: ($res)"

  let warnIcon =  ('{ "ok": "\u26a0\ufe0f" }' | from json | get ok)
  let okIcon =  ('{ "ok": "\u2705" }' | from json | get ok)

  let icon = if $"($res)" == "1" { $"($warnIcon) " } else { $"($okIcon) " }
  let sound = if $"($res)" == "1" { $"Funk" } else { $"xx" }

  terminal-notifier -sound $sound -message $des -title $"($icon)($msg)"

  store_notification $msg $res

  colored xterm_grey27 "-------------\n"
  print_current_env
}

def fh [--noSort] {
  let fl = (mktemp -p /tmp --suffix .nu)

  let noSortArg = if $noSort { ["--no-sort"] } else { [] }

  let cmd = (
    history | where cwd == (pwd) | reverse | uniq-by command | get command
      | where ($it | str length) < 200
      | where ($it | str length) > 9
      | each { $in | nu-highlight }
      | str join "\n"
      | fzf --ansi --extended ...$noSortArg
  )

  commandline edit $cmd
}

def push_as [src: string, dest: string] {
  docker tag $src $dest
  docker push $dest
}

def buildPath [path: string] {

  let dir = $path
  let name = $path | path basename
  let hash = $path | hash md5 | str substring 1..5
  let tag = $"($name)_($hash)"

  print { building: $path, ver: 13, name: $name, hash: $hash, tag: $tag, dir: $dir }

  docker build --progress plain -t $tag $dir
  print "---------"
  print ""
  print "---------"

  return $tag
}

def --wrapped buildRun [path: string, ...args] {
  docker run -it (buildPath $path) ...$args
}

def sv [path] {
  let dir = ($path | path dirname)

  if $dir != "" {
    ^mkdir -p $dir
  }

  $in | save --force $path

  $in
}

def mvs [path, target] {
  let dir = ($target | path dirname)

  if $dir != "" {
    mkdir $dir
  }

  mv $path $target
}

def cps [path, target] {
  let dir = ($target | path dirname)

  if $dir != "" {
    mkdir $dir
  }

  cp -r $path $target
}

def inbox_box [name] {
  let name = $"($name)_(random-hash)"
  let path =  $"~/Downloads/($name)" | path expand

  mkdir $path
  rv $path

  $path
}

def e [file] {
  ~/.config/bin/nvr_editor $file
}

def watch_copy [file] {
  cat $file | pbcopy
  watch $file { cat $file | pbcopy }
}

def --wrapped rge [...args] {
  rg --ignore-file ('~/.config/global.ignore' | path expand) ...$args
}

def --env nore_set_env [name, value] {
  if $name not-in $env {
    let update = { $name: $value }

    load-env $update
  }
}

def --env y [...args] {
	yazi ...$args
}

def ring [size = 10] {
  let len = $in | length
  print $len

  let start = [($len - $size), 0] | math max

  print { start: $start }

  $in |  slice $start..$len
}


let npath = "~/.local/share/nvim/notifications.json"

def store_notification [msg, status] {
  let notification = {
    message: $msg,
    date: (date now | format date "%+"),
    pwd: (pwd),
    branch: (branch),
    status: $status,
  }

  mut notifications = open_safe $npath | default [] | append $notification | ring 10

  $notifications | to json | sv $npath
}

def list_notifications [] {
  mut notifications = open_safe $npath | default [] | update date { $in | into datetime }
    | update status { if $in == 0 { $"(ansi green)success" } else { $"(ansi red_bold)error" } }
    | update pwd { $in | path expand | path relative-to $"($env.HOME)/p" }
    | where date > ((date now) - 12hr)
    | select -o date status message pwd branch

  print $notifications
}

def copy [] {
  $in | pbcopy

  _nvim_sync_clipboard

  $in
}

def last_dw [] {
  ls ~/Downloads/ | sort-by modified | last | get name
}

def persist_clipboard [$prefix = "cp"] {
  let id = $"($prefix)_(random-hash)"

  pbpaste | sv $"/tmp/cp/($id)"

  $"\(cp_restore ($id))" | pbcopy

  cp_restore $id
}

def cp_restore [$id] {
  open $"/tmp/cp/($id)"
}

def status_color [] {
  mut color = "red_bold"

  if $in == "online" { $color = "green_bold" }
  if $in == "running" { $color = "green_bold" }

  $"(ansi $color) ($in)"
}

def pm2_ls [] {
  let ns = (pwd | path basename)

  pm2 jlist | from json | where pm2_env.namespace == $ns | update name { $in | str replace $"-($ns)" "" }
    | select name pid pm2_env.status pm2_env.pm_uptime
    | rename name pid status uptime
    | update uptime { $"($in / 1000 | math round)" | into datetime -f '%s' }
    | update status { $in | status_color }
}

def silence [] {
  $in | lines | where ($it | str contains "[PM2]") | | each { print $in }

  print "\n"
}

def --wrapped pm2_command [cmd, ...services] {
  let ns = (pwd | path basename)

  mut ser = $services

  mut services_ns = $services | each { $"($in)-($ns)" }

  if (($services_ns | length) == 0) {
    $services_ns = [$ns]
  }

  pm2 $cmd ...$services_ns | silence

  pm2_ls
}

def --wrapped p [cmd, ...args] {
  pm2_command $cmd ...$args
}

def --wrapped pm2_stop [...services] {
  pm2_command stop ...$services
}

def --wrapped pm2_start [...services] {
  pm2_command start ...$services
}

def --wrapped pm2_restart [...services] {
  pm2_command restart ...$services
}

def defnull [defval] {
  if $in == "" {
    return $defval
  }

  if $in == null {
    return $defval
  }

  $in
}

def dt [fmt?: string] { date now | format date ($fmt | default "%D" ) }

def gt [name, def?: any] {
  $in | get -o $name | default $def
}

def --wrapped build [--args: any, ...rest] {
  mut eargs = []

  for $x in ($args | transpose | rename k v) {

    $eargs = $eargs | append "--build-arg" | append $"($x.k)=($x.v)"
    print $x
  }

  docker build --progress plain ...$eargs ...$rest
}

def --wrapped gpt [...args] {
  let url = {
    scheme: https, host: "chatgpt.com", params: {
      temporary-chat: "true",
      mode: "gpt-5",
      hints: "search",
      q: ($args | str join " "),
    }
  } | url join
  opn $url
}

def pdot [] {
  p Dotfiles
}


def tmp [suffix = ""] {
  in /tmp { mktemp -t --suffix $suffix}
}

def get_cached [url] {
  once $url { random-hash }
}

def jsonl [] {
  $in | lines | each { $in | from json }
}

def raw [] {
  $in | str join "\n"
}

def tmpd [suffix = ""] {
  in /tmp { mktemp -d -t --suffix $suffix}
}

def code_hash [] {
  $"(git diff | md5)_(git rev-parse HEAD)" | md5 | str substring 0..10
}

def files [path = "."] {
  rg --files $path | fzf --min-height=20 --margin=10,2 --layout=reverse --preview 'bat --style=numbers --color=always --line-range :500 {}' | lines | each { edit $in }
}

def filesw [path = "."] {
  while true { files $path; sleep 200ms }
}

def app [name] {
  ^open -a $name
}

# cheatsheet:
# basic: if-else, for over array, array filter
# regexp: match, replace

def apps [] {
  let apps = (ls /Applications /System/Applications | gt name)

  whatever {
    let app = $apps | each { $in | path basename | str replace -r '\..+' '' } | str join "\n"
      | fzf --min-height=20 --margin=10,20 --layout=reverse

    app $app
  }

  exit
}

def bang [...args] {
  let q = $args | str join " "

  let url = {
    scheme: https
    host: "duckduckgo.com"
    params: {
      q: $"($q) !"
    }
  } | url join

  opn $url
}


def cal [] {
  app Calendar
}

def tmp_mail [] {
  "lasek.accounts@icloud.com" | copy
}

def once [id: string, cl: closure] {
  let file = $"/tmp/($id | md5)";

  if ($file | path exists) {
    open --raw $file | from json | gt value
  } else {
    let output = (do $cl)

    { value: $output } | to json | save $file

    $output
  }
}

def free_port [] {
  let last = (open /Users/billy/p/_billy/free_port | into int)

  $last + 1 | sv /Users/billy/p/_billy/free_port
}

def execute_curl [curlBody] {
  bash -c ($curlBody | str replace "curl" "curl -is" | tee { $in | bat -l bash })
}

def danger [] {
  print "the action is dangerous, do you want to continue? (y/n)"
  let response = input
  if $response != "y" {
    exit 1
  }
}

def cleanup [] {
  git add .;
  git reset --hard HEAD;
  git clean -fd
}

def ilike [col, reg] {
  $in | where ($it | get $col) =~ $"\(?i)($reg)"
}

# Claude Code entrypoint
def --wrapped cl [--print(-p), --auto(-a), --sonnet(-s), ...args] {
  mut clArgs = []

  $env.CLAUDE_CODE_HIDE_ACCOUNT_INFO = "1"
  $env.IS_DEMO = "1"

  if $print {
    $clArgs = ($clArgs | append "-p")
  }

  if $auto {
    $clArgs = ($clArgs | append "--enable-auto-mode")
  }

  # Append the prompt itself
  $clArgs = ($clArgs | append ($args | str join " "))

  let model = if $sonnet { "claude-sonnet-4-6" } else { "claude-opus-4-6" }

  # print $clArgs
  $in | claude ...$clArgs
}

def pbar [
  current: int,    # current step
  total: int,      # total steps
  --width: int = 30  # bar width in characters
] {
  let pct = ($current / $total * 100 | math round)
  let filled = ($current / $total * $width | math round | into int)
  let empty = $width - $filled
  let bar = $"('' | fill -c '█' -w $filled)('' | fill -c '░' -w $empty)"

  $"[($bar)] ($pct)%"
}

def diff [] {
  git add .; git diff --cached
}
