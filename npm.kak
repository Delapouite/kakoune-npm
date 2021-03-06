# options

declare-option -hidden str-list npm_deps
declare-option -hidden completions npm_completions
declare-option -hidden line-specs npm_flags

# commands

define-command npm-info -docstring 'show dependency info on a package.json current line' %{
  npm-select-package-name
  evaluate-commands %sh{
    desc=$(curl -s https://registry.npmjs.org/"$kak_selection" | jq -r '(.name + "@" + .["dist-tags"].latest + ": " + .description)')
    if [ -n "$desc" ]; then
      printf '%s\n' "info -anchor $kak_cursor_line.$kak_cursor_column %^$desc^"
    else
      echo "fail npm: no info available on registry for $kak_selection"
    fi
  }
}

# kakoune will prompt for buffer refresh at the end
define-command npm-update-latest -docstring 'update to package@latest on current line' %{
  npm-select-package-name
  nop %sh{ npm i "${kak_selection}@latest" < /dev/null > /dev/null 2>&1 & }
}

# kakoune will prompt for buffer refresh at the end
define-command yarn-upgrade-latest -docstring 'upgrade to package@latest on current line' %{
  npm-select-package-name
  nop %sh{ yarn upgrade "${kak_selection}@latest" < /dev/null > /dev/null 2>&1 & }
}

define-command npm-get-deps -docstring 'find deps in nearest package.json and populate npm_deps option' %{
  evaluate-commands %sh{
    package_json="$(dirname $(npm root))/package.json"
    deps=$(cat "$package_json" | jq --raw-output '.dependencies | keys | join(" ")')
    core_deps=$(node -pe 'repl._builtinLibs.join(" ")')
    echo "set global npm_deps $deps $core_deps"
  }
}

define-command npm-edit-package-json -docstring 'open nearest package.json' %{
  edit %sh{ echo "$(dirname $(npm root))/package.json" }
}

# hidden commands

# grab the key in package.json
define-command -hidden npm-select-package-name %{
  execute-keys <a-x>1s"(.*)":<ret>
}

define-command -hidden npm-complete -params 0..1 %{
  try %{
    evaluate-commands %sh{
      candidates=''
      search="$1"
      pattern="$1"'*'

      # filter deps according to given param 1 if it's provided
      eval "set -- $kak_opt_npm_deps"
      while [ "$1" ]; do
        case "$1" in
          $pattern) candidates="$candidates $1||$1";;
        esac
        shift
      done

      word_col=$((kak_cursor_column - ${#search}))
      prefix="${kak_cursor_line}.${word_col}@${kak_timestamp}"

      echo "set-option buffer=$kak_bufname npm_completions ${prefix} ${candidates}"
    }
  }
}

# hooks

hook global WinSetOption filetype=(javascript|ecmascript) %{
  # populate option once
  npm-get-deps
  set-option window completers option=npm_completions %opt{completers}

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
        execute-keys -draft 'h<a-i><a-w> 1srequire\([''"]([^''"]*)<ret> "my'
        npm-complete %reg{m}
      }

    } catch %{ try %{

      # before first char has been typed, it offers the whole (unfiltered) list of modules
      evaluate-commands %{
        execute-keys -draft 'h<a-i><a-w> srequire\([''"]<ret>'
        npm-complete
      }

    } catch %{ try %{

      evaluate-commands -save-regs m %{
        execute-keys -draft 'xH 1simport(?:.*?)from [''"]([^''"]*)<ret> "my'
        npm-complete %reg{m}
      }

    } catch %{ try %{

      evaluate-commands %{
        execute-keys -draft 'xH simport(?:.*?)from [''"]<ret>'
        npm-complete
      }

    } catch %{

      set-option buffer npm_completions ''

    } } } } # 1 per catch clause

  } # hook
}

