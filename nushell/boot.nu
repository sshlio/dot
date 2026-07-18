# Copyright (c) 2026 Sławomir Laskowski
# SPDX-License-Identifier: MIT

def edit [path] {
  print $"(ansi -o "7123")($path | path expand | base64)(ansi string_terminator)"
}

def "notify nvim" [message] {
  print $"(ansi -o "7125")($message | base64)(ansi string_terminator)"
}

def _nvim_sync_clipboard [] {
  print $"(ansi -o "7124")clipboard(ansi string_terminator)"
}
