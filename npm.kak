def npm-info -docstring 'show dependency info on a package.json current line' %{
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

decl -hidden str npm_deps
decl -hidden completions npm_completions

def npm-get-deps -docstring 'find deps in nearest package.json and populate npm_deps option' %{
  %sh{
    package_json="$(dirname $(npm root))/package.json"
    deps=$(cat "$package_json" | jq --raw-output '.dependencies | keys | join(":")')
    echo "set global npm_deps %{$deps}"
  }
}

def -hidden npm-complete -params 1 %{
  try %{
    set buffer npm_completions %sh{
      candidates=''
      pattern="$1"'*'

      # filter deps according to given param 1
      while read dep; do
        case "$dep" in
          $pattern) candidates="$candidates:$dep||$dep";;
        esac
      done <<< $(printf '%s\n' "$kak_opt_npm_deps" | tr ':' '\n')

      word_col=$((kak_cursor_column - ${#1}))
      prefix="${kak_cursor_line}.${word_col}@${kak_timestamp}"

      echo "${prefix}${candidates}"
    }
  }
}

hook global WinSetOption filetype=(javascript|ecmascript) %{
  # populate option once
  npm-get-deps
  set window completers "option=npm_completions:%opt{completers}"

  hook -group npm_complete buffer InsertIdle .* %{
    try %{
      # the m register stores the module name after "require('"
      eval -save-regs m %{
        exec -draft 'h<a-i>W 1srequire\([\'"]([^\'"]*)<ret> \"my'
        npm-complete %reg{m}
      }
    } catch %{
      set buffer npm_completions ''
    }
  }
}
