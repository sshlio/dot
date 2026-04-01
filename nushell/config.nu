# Copyright (c) 2026 Sławomir Laskowski
# SPDX-License-Identifier: MIT

$env.TRUSTED_PROJECTS = []

source "~/.config/nushell/config.local.nu"

$env.config = {
  show_banner: false

  history: {
    file_format: "sqlite"
    isolation: true
  }

  use_kitty_protocol: true

  table: {
    mode: light
  }

  edit_mode: vi

  keybindings: [
    {
      name: forward
      modifier: control
      keycode: char_f
      mode: vi_insert
      event: {
          until: [
              {send: historyhintwordcomplete}
              {edit: movewordright}
          ]
      }
    }
    {
      name: forward
      modifier: super
      keycode: char_f
      mode: vi_insert
      event: { send: historyhintwordcomplete }
    }

    {
      name: forward
      modifier: control
      keycode: char_g
      mode: vi_insert
      event: { send: OpenEditor }
    }

    {
      name: forward
      modifier: control
      keycode: char_v
      mode: vi_insert
      event: { edit: pastecutbufferbefore }
    }

    {
      modifier: super
      keycode: char_c
      mode: vi_insert
      event: { send: CtrlC }
    }

    {
      modifier: super
      keycode: char_d
      mode: vi_insert
      event: { send: ExecuteHostCommand, cmd: 'exit' }
    }

    {
      modifier: super
      keycode: char_g
      mode: vi_insert
      event: { send: ExecuteHostCommand, cmd: 'project_desired' }
    }
    {
      modifier: none
      keycode: up
      mode: vi_insert
      event: {
        until: [
            # {send: HistoryHintWordComplete}
            # {send: HistoryHintComplete}
            # {send: PreviousHistory}
            # {send: MenuUp}
            {send: Up}
        ]
      }
    }
    {
      name: vinormal
      modifier: alt
      keycode: char_m
      mode: vi_insert
      event: [
        { send: esc }
        { send: esc }
      ]
    }
  ]

  # buffer_editor: "nvr_edit"
}


$env.config.shell_integration.osc2 = false
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.MAIN_BRANCH = "main"
$env.GH_ROOT = ""

$env.EDITOR = $"vim"

$env.PROMPT_EXTRA = ""
$env.PROMPT_COMMAND = { ||
  let branch = (do { git rev-parse --abbrev-ref HEAD } | complete)
  let dirty = if $branch.exit_code == 0 { (do { git status --porcelain } | complete).stdout | str trim | if ($in | is-empty) { "" } else { "'" } } else { "" }
  let branch_name = ($branch.stdout | str trim)
  let branch_color = if $branch_name in [development master main] { "dark_gray_dimmed" } else { "xterm_lightsteelblue" }
  let git = if $branch.exit_code == 0 { $" (ansi $branch_color)󰊢 ($branch_name)($dirty)(ansi reset)" } else { "" }

  let profile = ($env | get -o AWS_PROFILE)
  let showAws = (($profile| is-not-empty) and ($profile != "staging"))

  let aws = if ($showAws) { $" (ansi xterm_lightgoldenrod2) ($env.AWS_PROFILE)(ansi reset)" } else { "" }

  $"\n(ansi green_bold)(pwd | path basename)(ansi reset)($git)($aws)($env.PROMPT_EXTRA)\n(ansi dark_gray_dimmed)$(ansi reset) "
}
$env.PROMPT_COMMAND_RIGHT = { || "" }

source ~/.config/nushell/utils.nu

def hookConfig --env [] {
  let cwd = (pwd | path expand)
  mut hook = ['source ~/.config/nushell/utils.nu']
  let is_trusted = ($env.TRUSTED_PROJECTS | any {|trusted| ($trusted | path expand) == $cwd })
  let has_local_env = ("_billy/.env.nu" | path exists)
  let has_user_env = ("_billy/user.env.nu" | path exists)

  if ("~/p/_billy/global.env.nu" | path exists) {
    $hook = $hook | insert 0 'source ~/p/_billy/global.env.nu'
  }

  if $is_trusted and $has_local_env {
    $hook = $hook | insert 0 'source _billy/.env.nu'
  }

  if (not $is_trusted) and ($has_local_env or $has_user_env) {
    print $"(ansi yellow)warning:(ansi reset) local nushell config present but project is not trusted: ($cwd)"
  }

  $env.config.hooks = {
    pre_prompt: $hook,
    pre_execution: $hook,
    # env_change: {
    #   PWD: {|before, after| hookConfig }
    # }
  }
}

hookConfig

def monitor [
  --dur(-d): duration = 100ms, # time between retries
  command: closure, # command to run
] {
  loop {
      let till = (date now) + $dur
      let out = do $command
      tput clear
      $out | print
      sleep ($till - (date now))
  }
}

def p-path-compl [] {
  ls ~/p | select name | update name { |it| basename $it.name } | rename value
}

def n-path-compl [] {
  ls ~/p | select name | update name { |it| basename $it.name } | rename value
}

def disown [...command: string] {
 sh -c '"$@" </dev/null >/dev/null 2>/dev/null & disown' $command.0 ...$command
}

def project [path: string@"p-path-compl"] {
  cd $"~/p/($path)"

  try {
    loop {
      nvim
    }
  }

  exit
}

def pp [path?: string@"p-path-compl"] {
  let p = if ($path | is-empty) {
    p-path-compl | get value | to text | fzf | str trim
  } else {
    $path
  }

  in $"~/p/($p)" { nvim }
}

# def vide [name: string@"p-path-compl"] {
#   in $"~/p/($name)" {
#     let rv = (
#       whatever {
#         let pid = (open_safe .nvim/neovide.pid | into int)
#
#         ~/.config/bin/WindowServer $pid out+err> /dev/null
#       }
#     )
#
#     if $rv != 0 {
#       bash ~/.config/bin/vide.sh
#     }
#   }
# }

def boostrap [] {
  project Dotfiles
}



