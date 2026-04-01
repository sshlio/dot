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
