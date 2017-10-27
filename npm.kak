def npm-info -docstring 'show dependency info on a package.json current line' %{
  # select package name
  exec <a-x>1s"(.*)":<ret>
  %sh{
    desc=$(curl -s http://registry.npmjs.org/"${kak_selection}"/latest | jq -r '(.name + "@" + .version + ": " + .description)')
    if [ -n "$desc" ]; then
      printf '%s\n' "info -anchor $kak_cursor_line.$kak_cursor_column %^$desc^"
    else
      echo 'npm: no info available'
    fi
  }
}

def npm-update-latest -docstring 'update to package@latest on current line' %{
  # select package name
  exec <a-x>1s"(.*)":<ret>
  %sh{ npm i "${kak_selection}@latest" < /dev/null > /dev/null 2>&1 & }
}

decl -hidden str-list npm_deps
decl -hidden completions npm_completions

def npm-get-deps -docstring 'find deps in nearest package.json and populate npm_deps option' %{
  %sh{
    package_json="$(dirname $(npm root))/package.json"
    deps=$(cat "$package_json" | jq --raw-output '.dependencies | keys | join(":")')
    core_deps=$(node -pe "require('repl')._builtinLibs.join(':')")
    echo "set global npm_deps %{$deps:$core_deps}"
  }
}

def -hidden npm-complete -params 0..1 %{
  try %{
    set buffer npm_completions %sh{
      candidates=''
      pattern="$1"'*'

      # filter deps according to given param 1 if it's provided
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
    # these 'try' guard against expected 'nothing selected' errors, raised by their following exec command
    # 4 attempts:
    # require('foo
    # require('
    # import foo from 'foo
    # import foo from '

    try %{

      # the m register stores the module name after "require('"
      eval -save-regs m %{
        exec -draft 'h<a-i>W 1srequire\([\'"]([^\'"]*)<ret> \"my'
        npm-complete %reg{m}
      }

    } catch %{ try %{

      # before first char has been typed, it offers the whole (unfiltered) list of modules
      eval %{
        exec -draft 'h<a-i>W srequire\([\'"]<ret>'
        npm-complete
      }

    } catch %{ try %{

      eval -save-regs m %{
        exec -draft 'xH 1simport(?:.*?)from [\'"]([^\'"]*)<ret> \"my'
        npm-complete %reg{m}
      }

    } catch %{ try %{

      eval %{
        exec -draft 'xH simport(?:.*?)from [\'"]<ret>'
        npm-complete
      }

    } catch %{

        set buffer npm_completions ''

    } } } } # 1 per catch clause

  } # hook
}
