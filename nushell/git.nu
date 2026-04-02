def wip [] {
  let messages = [
    "Fiddling"
    "Thinking"
    "Tinkering"
    "Pondering"
    "Adjusting"
    "Polishing"
    "Tweaking"
    "Massaging"
    "Wrangling"
    "Coaxing"
    "Fussing"
    "Juggling"
    "Patching"
    "Mending"
    "Untangling"
    "Refining"
    "Smoothing"
    "Futzing"
    "Noodling"
    "Wiggling"
    "Bothering"
  ]

  c $"($messages | shuffle | first)..."
}

def ghb [] {
  let repoUrl = (
    git remote get-url origin
    | str trim
    | str replace -r '^(git@|ssh://git@)github\.com[:/]' 'https://github.com/'
    | str replace -r '\.git$' ''
  )

  let currentBranch = (git branch --show-current)

  $repoUrl

  if ($currentBranch == $env.MAIN_BRANCH) {
    ^open $"($repoUrl)/commits/($currentBranch)"
  } else {
    ^open $"($repoUrl)/compare/($currentBranch)"
  }
}
