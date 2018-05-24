# kakoune-npm

[kakoune](http://kakoune.org) plugin to work with [npm](https://www.npmjs.com/) and [yarn](https://yarnpkg.com), the JavaScript package managers.

## Install

Add `npm.kak` to your autoload dir: `~/.config/kak/autoload/`.

To use the `npm-info` command, you need to have [jq](https://stedolan.github.io/jq/) on your system.

## Usage

It provides the following commands:

- `npm-info`: show dependency info on package.json current line
- `npm-update-latest`: update to package@latest on current line (bump major)
- `yarn-upgrade-latest`: upgrade to package@latest on current line (bump major)

It also offers basic autocompletion in insert mode. While typing something like:

```js
const React = require('re[]
```

or

```js
import React from 're[]
```

This plugin extracts all dependencies listed in the `package.json` of the current project.
This list is merged with the node core modules list like `fs`, `path`, `http`…

Everytime it detects `require('`, or `import foo from '` it will attempt to match the following word
against this dependencies list.

## See also

- [kakoune-ecmascript](https://github.com/Delapouite/kakoune-ecmascript)
- [kakoune-typescript](https://github.com/atomrc/kakoune-typescript)
- [kakoune-flow](https://github.com/Delapouite/kakoune-flow) - Flow type-checking and coverage
- [kakoune-grasp](https://github.com/Delapouite/kakoune-grasp) - Text objects based on AST
- [kakoune-goto-file](https://github.com/Delapouite/kakoune-goto-file) - Enhanced `gf` for `node_modules`

## Licence

MIT
