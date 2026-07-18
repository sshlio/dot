def main [] {}
def "main check_nvim" [] {
  let stderr = nvim --headless '+qa' | complete | get stderr | lines

  if (($stderr | where { $in =~ "Error" } | length) > 0) {
    print $stderr
    exit 1
  }
}
