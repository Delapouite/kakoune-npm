def npm-info -docstring 'show dependency info on package.json current line' %{
  # select package name
  exec <a-x>1s"(.*)":<ret>
  %sh{
    desc=$(curl -s http://registry.npmjs.org/"${kak_selection}"/latest | jq -r '(.name + "@" + .version + ": " + .description)')
    if [ -n "$desc" ]; then
      echo "echo -debug $desc"
      printf '%s\n' "info -anchor $kak_cursor_line.$kak_cursor_column %^$desc^"
    else
      echo 'npm: no info available'
    fi
  }
}
