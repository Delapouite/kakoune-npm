# kakoune-npm

[kakoune](http://kakoune.org) plugin to work with [npm](https://www.npmjs.com/), the JavaScript package manager.

## Install

Add `npm.kak` to your autoload dir: `~/.config/kak/autoload/`.

To use the `npm-info` command, you need to have [jq](https://stedolan.github.io/jq/) on your system.

## Usage

It provides the following commands:

- `npm-info`: show dependency info on package.json current line

It also offers basic autocompletion in insert mode. While typing something like:

```js
const React = require('re[]
```

This plugin extracts all dependencies listed in the `package.json` of the current project.
This list is merged with the node core modules list like `fs`, `path`…
Everytime it detects `require('` or `require("` it will attempt to match the following word
against this dependencies list. `import` statements are not supported yet.

## See also

- [kakoune-ecmascript](https://github.com/Delapouite/kakoune-ecmascript)
- [kakoune-typescript](https://github.com/atomrc/kakoune-typescript)
- [kakoune-flow](https://github.com/Delapouite/kakoune-flow)
- [kakoune-grasp](https://github.com/Delapouite/kakoune-grasp)

## Licence

MIT
