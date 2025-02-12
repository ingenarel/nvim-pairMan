Ever wanted to change your () to {} or put a [] inside it without typing too much? This plugin does exactly that.

It can work with any type of pairs, non matching ones, and matching ones, and it works with `vim.opt.matchpairs` too.

It can:
- delete pairs
- change pairs
- put stuff inside / outside of pairs

And it does all of that by simulating keystrokes, the normal vim commands. So no need for additional dependencies like treesitter 

## This help page, the readme, and the lua docstrings in the plugin files might not be in sync.

I'll try to figure out a way to make them generate from the lua docstrings. Until then if you have a lua lsp (i use
lua_ls) you can include this in you library. I personally set the library option to: 
```lua
library = vim.api.nvim_get_runtime_file("", true)
```
then you can just hover over a function or a var with K and see it's docs if it has them. or use ^] to go to the
function.

If you haven't set up lsp yet, you can set everything up easily with these 3 plugins:
- mason
- nvim-lspconfig
- mason-lspconfig

# setup

to quicky setup the motions, i do this: 
```lua
require("pairMan").setup{keymap="<leader>p"}
```
these are copy pasted then edited from the function docs: 


```lua
---@param opts {keymap:string?, changerKeymap:string?, inserterKeymap:string?}
```

`keymap:` sets both the `changerKeymap` and the `inserterKeymap` prefix

`changerKeymap:` sets the prefix for pair changer keymaps. that means changing [] to (), etc.

`inserterKeymap:` sets the prefix for pair inserter keymaps. that means inserting [] inside/outside ()

If you're using the leader key in any of these, be sure that the leader key is set up before calling this function.

`buflocal:` If true, make the keymaps local to the current buffer. also the current buffer's |matchpairs| option is
read.

If buflocal not true, it makes keymaps globally, and reads the global matchpairs option.

For most people it would be enough, but |matchpairs| itself can be set locally for buffers. if you set your c files to
match <:> via:
```lua
vim.opt_local.matchpairs = "(:),{:},[:],<:>"
```
and if buflocal isn't true, this plugin won't work with <:>.

to fix this, you either need to add <:> globally, or call this setup in an |autocommand| or a |filetype-plugin|.

i tried to make an option where the setup would create an autocommand, and when you enter a buffer, it reads the current
matchpairs option, and set the keymaps accordingly, but it was causing a lot of issues. i'm not a neovim expert, so i
currently don't know how to do it. but i'll try.



# pairman.PairChanger()

function for pair manupulation.

it can work with the `matchpairs` option, and it can also work with qoutes using regexes

these are copy pasted then edited from the function docs: 


```lua
---@param chars? [string?, string?]
```
should be a pair of chars that you want to set the current pair to. eg: if you want to change [] to (), you would call
this while you're on top the pair: 
```lua
require("pairMan").PairChanger{"(", ")"}
```

if you want to delete a pair, you should omit this var.

if firstChar == lastChar you can omit last char 
```lua
require("pairMan").PairChanger{'"'}
```
is the same as: 
```lua
    require("pairMan").PairChanger{'"', '"'}
```


```lua
---@param backwards? boolean
```
if true, backwards search a regex pair.

some random line: abcd"efg"hijkl

you want to change the double qoutes to a single qoute.

if your cursor is on the qoute that's between `d` and `e` you can do: 
```lua
require("pairMan").PairChanger{"'"}
```
but if your cursor is on the qoute that's between `g` and `h`, you need to do: 
```lua
    require("pairMan").PairChanger({"'"}, true)
```



# pairman.PairInserter()

function for pair insertion.

it can work with the `matchpairs` option, and it can also work with qoutes using regexes

these are copy pasted then edited from the function docs: 

```lua
---@param chars [string?, string?]
```
should be a pair of chars that you want to insert inside/outside the current pair.

if firstChar == lastChar you can omit last char 
```lua
require("pairMan").PairInserter{'"'}
```
is the same as: 
```lua
require("pairMan").PairInserter{'"', '"'}
```


```
---@param motion ("a"|"i")
```
`a` means insert pair outside, `i` means inside.
if you want to put [] inside (), you would call this while you're on top the pair: 
```lua
require("pairMan").PairInserter({"(", ")"}, "a")
```


```lua
---@param backwards? boolean
```
if true, backwards search a regex pair.

some random line: abcd`"`efg`"`hijkl

you want to insert single qoutes between the double qoutes.

if your cursor is on the qoute that's between `d` and `e` you can do: 
```lua
require("pairMan").PairInserter({"'"}, "i")
```
but if your cursor is on the qoute that's between `g` and `h`, you need to do: 
```lua
require("pairMan").PairInserter({"'"}, "i", true)
```
