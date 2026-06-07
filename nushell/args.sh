new_args=()
for arg in "$@"; do
  new_args+=(";$arg")
done

jq -n --args '$ARGS.positional' "${new_args[@]}"
