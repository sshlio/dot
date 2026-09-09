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

def c [...$msg] {
  let branch = (git branch --show-current | str trim)

  if ($branch in [main development master]) and ($env.ALLOW_COMMIT_MAIN? != "yes") {
    danger $"commit and push directly to '($branch)'? \(y/n)"
  }

  git add .
  git commit -m $"($msg | str join ' ')"
  git push
}
