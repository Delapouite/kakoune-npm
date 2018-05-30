# options

declare-option -hidden str-list npm_deps
declare-option -hidden completions npm_completions
declare-option -hidden line-specs npm_flags

# commands

# grab the key in package.json
define-command npm-select-package-name -hidden %{
  execute-keys <a-x>1s"(.*)":<ret>
}

define-command npm-info -docstring 'show dependency info on a package.json current line' %{
  npm-select-package-name
  %sh{
    desc=$(curl -s https://registry.npmjs.org/"$kak_selection"/latest | jq -r '(.name + "@" + .version + ": " + .description)')
    if [ -n "$desc" ]; then
      printf '%s\n' "info -anchor $kak_cursor_line.$kak_cursor_column %^$desc^"
    else
      echo "echo -markup {Error}npm: no info available on registry for $kak_selection"
    fi
  }
}

define-command npm-update-latest -docstring 'update to package@latest on current line' %{
  npm-select-package-name
  %sh{ npm i "${kak_selection}@latest" < /dev/null > /dev/null 2>&1 & }
}

define-command yarn-upgrade-latest -docstring 'upgrade to package@latest on current line' %{
  npm-select-package-name
  %sh{ yarn upgrade "${kak_selection}@latest" < /dev/null > /dev/null 2>&1 & }
}

define-command npm-get-deps -docstring 'find deps in nearest package.json and populate npm_deps option' %{
  %sh{
    package_json="$(dirname $(npm root))/package.json"
    deps=$(cat "$package_json" | jq --raw-output '.dependencies | keys | join(":")')
    core_deps=$(node -pe "repl._builtinLibs.join(':')")
    echo "set global npm_deps %{$deps:$core_deps}"
  }
}

# hidden commands

define-command -hidden npm-complete -params 0..1 %{
  try %{
    set-option buffer npm_completions %sh{
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

# hooks

hook global WinSetOption filetype=(javascript|ecmascript) %{
  # populate option once
  npm-get-deps
  set-option window completers "option=npm_completions:%opt{completers}"

  hook -group npm_complete buffer InsertIdle .* %{
    # these 'try' guard against expected 'nothing selected' errors, raised by their following exec command
    # 4 attempts:
    # require('foo
    # require('
    # import foo from 'foo
    # import foo from '

    try %{

      # the m register stores the module name after "require('"
      evaluate-commands -save-regs m %{
        execute-keys -draft 'h<a-i><a-w> 1srequire\([\'"]([^\'"]*)<ret> \"my'
        npm-complete %reg{m}
      }

    } catch %{ try %{

      # before first char has been typed, it offers the whole (unfiltered) list of modules
      evaluate-commands %{
        execute-keys -draft 'h<a-i><a-w> srequire\([\'"]<ret>'
        npm-complete
      }

    } catch %{ try %{

      evaluate-commands -save-regs m %{
        execute-keys -draft 'xH 1simport(?:.*?)from [\'"]([^\'"]*)<ret> \"my'
        npm-complete %reg{m}
      }

    } catch %{ try %{

      evaluate-commands %{
        execute-keys -draft 'xH simport(?:.*?)from [\'"]<ret>'
        npm-complete
      }

    } catch %{

      set-option buffer npm_completions ''

    } } } } # 1 per catch clause

  } # hook
}
