local m = {}

---@nodoc local simkeys() {{{
---@nodoc docs {{{
---### This function uses |nvim_feedkeys()| to simulate key presses. The `n` flag is turned on.
---termcodes are automatically replaced.
---@param keys string the keys that you want to simulate.
------
---@nodoc docs }}}
local function simkeys(keys)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end --}}}

---@nodoc local returnMatchPairs() {{{
---@nodocs docs {{{
---returns what chars are in the matchpairs option.
---the first table is the first item from each pair, and the last table is the last item from each pair.
---eg: if the value of |matchpairs| is `"(:),{:},[:],<:>"` then it returns
---```lua
---{ "(", "{", "[", "<" },
---{ ")", "}", "]", ">" }
---```
---@param global boolean? if false, return the local value, else return the global value
---@nodoc docs }}}
local function returnMatchPairs(global)
    local firstChars = {}
    local lastChars = {}
    if global == false then
        for a in vim.gsplit(vim.opt_local.matchpairs._value, ",") do
            local x = vim.split(a, ":")
            table.insert(firstChars, x[1])
            table.insert(lastChars, x[2])
        end
    else
        for a in vim.gsplit(vim.opt_global.matchpairs._value, ",") do
            local x = vim.split(a, ":")
            table.insert(firstChars, x[1])
            table.insert(lastChars, x[2])
        end
    end
    return firstChars, lastChars
end --}}}

---@nodocs local initPairManupulation(){{{
---@nodocs docs{{{
---### this the the initialization function of the variables for pair manupulation.
---this should be called internally in PairChanger() and in PairInserter() at the start.
---@param chars? [string, string] see m._chars for more info.
---@param backwards boolean? see m._backwards for more info.
---@nodocs docs}}}
local function initPairManupulation(chars, backwards)
    ---@nodoc TODO: somehow fix the docstrings when using a `,`
    m._firstChars, m._lastChars = returnMatchPairs()

    ---@nodocs docs{{{
    ---### this is a shared value to make debugging easier, and the init for each function short.
    ---@type char the current char under the cursor when the last function was called.
    ---@nodocs docs}}}
    m._charUnderCursor = vim.fn.strpart(vim.fn.getline("."), vim.fn.col(".") - 1, 1)
    if m._charUnderCursor == '"' or m._charUnderCursor == "'" then
        m._charUnderCursor = "\\" .. m._charUnderCursor
    end

    ---@nodocs docs{{{
    ---### this is a shared value to make debugging easier, and the init for each function short.
    ---@type [string, string]? the char list that was passed to the last function call. either both elements could be
    ---nil, or both elements could be a string. if the second one is nil, and not the first one, then the first one's
    ---value is copied to the second one's value.
    ---see |PairChanger|'s or |PairInserter|'s documentation for more info about chars.
    ---@nodocs docs}}}
    m._chars = chars
    if m._chars == nil then
        m._chars = {}
    end
    if m._chars[1] ~= nil and m._chars[2] == nil then
        m._chars[2] = m._chars[1]
    end

    ---@nodocs docs{{{
    ---### this is a shared value to make debugging easier, and the init for each function short.
    - -- regex that's used for finding the char, \ ignored, that means if you're trying to find a `"` it will ignore
    - -- `\"`
    - -- each `\` needs to be doubled. because it's value gets passed to a string.
    - -- so a `\` becomes `\\` in this string, but when it's value get's passed to another string, it becomes `\` again.
    - -- solution? double the `\\` to `\\\\` so it becomes a `\\` in the end.
    ---@nodocs docs}}}
    m._regex = "\\\\%(\\\\\\\\\\\\)\\\\@<!" .. m._charUnderCursor

    ---@nodocs docs{{{
    ---### this is a shared value to make debugging easier, and the init for each function short.
    ---@type boolean? this is the backwards value that was passed to the last function call.
    ---see |PairChanger|'s or |PairInserter|'s documentation for more info about backwards.
    ---@nodocs docs}}}
    m._backwards = backwards

    if m._backwards == nil then
        m._backwards = false
    end

    simkeys("v<ESC>")
end -- }}}

---@nodoc PairChanger() {{{
---@nodoc docs {{{
---### function for pair manupulation.
---it can work with the matchpairs option, and it can also work with qoutes using regexes
------
---@param chars? [string, string] should be a pair of chars that you want to set the current pair to.
---eg: if you want to change [] to (), you would call this while you're on top the pair:
---```lua
---require("pairMan").PairChanger{"(", ")"}
---```
---if you want to delete a pair, you should omit this var.
---
---if firstChar == lastChar you can omit last char
---```lua
---require("pairMan").PairChanger{'"'}
---```
---is the same as:
---```lua
---require("pairMan").PairChanger{'"', '"'}
---```
---@param backwards? boolean if true, backwards search a regex pair.
---some random line: abcd`"`efg`"`hijkl
---you want to change the double qoutes to a single qoute.
---if your cursor is on the qoute that's between `d` and `e` you can do:
---```lua
---require("pairMan").PairChanger{"'"}
---```
---but if your cursor is on the qoute that's between `g` and `h`, you need to do:
---```lua
---require("pairMan").PairChanger({"'"}, true)
---```
---@nodoc docs }}}
function m.PairChanger(chars, backwards)
    initPairManupulation(chars, backwards)

    local afterSwitchLine = vim.fn.getline(".")

    if m._chars[1] == nil then
        if vim.list_contains(m._firstChars, m._charUnderCursor) then
            simkeys("%xgv<ESC>x")
        elseif vim.list_contains(m._lastChars, m._charUnderCursor) then
            simkeys("%xgv<ESC>")
            if vim.fn.col(".") == vim.fn.col("$") - 1 then
                simkeys("x")
            else
                simkeys("hx")
            end
        else
            if m._backwards == false then
                simkeys(":lua vim.fn.search('" .. m._regex .. "')<CR>xgv<ESC>x")
            else
                simkeys(":lua vim.fn.search('" .. m._regex .. "', 'b')<CR>xgv<ESC>")
                if vim.fn.col(".") == vim.fn.col("$") - 1 or afterSwitchLine ~= vim.fn.getline(".") then
                    simkeys("x")
                else
                    simkeys("hx")
                end
            end
        end
    else
        if vim.list_contains(m._firstChars, m._charUnderCursor) then
            simkeys("%r" .. m._chars[2] .. "gv<ESC>" .. "r" .. m._chars[1])
        elseif vim.list_contains(m._lastChars, m._charUnderCursor) then
            simkeys("%r" .. m._chars[1] .. "gv<ESC>" .. "r" .. m._chars[2])
        else
            if vim.list_contains(m._lastChars, m._chars[1]) then
                simkeys(
                    ":lua vim.fn.search('" .. m._regex .. "', 'b')<CR>r" .. m._chars[2] .. "gv<ESC>r" .. m._chars[1]
                )
            elseif vim.list_contains(m._firstChars, m._chars[1]) or m._backwards == false then
                simkeys(":lua vim.fn.search('" .. m._regex .. "')<CR>r" .. m._chars[2] .. "gv<ESC>r" .. m._chars[1])
            else
                simkeys(
                    ":lua vim.fn.search('" .. m._regex .. "', 'b')<CR>r" .. m._chars[1] .. "gv<ESC>r" .. m._chars[2]
                )
            end
        end
    end
end -- }}}

---@nodoc PairInserter() {{{
---@nodoc docs {{{
---### function for pair insertion.
---it can work with the matchpairs option, and it can also work with qoutes using regexes
---
---@param chars? [string, string] should be a pair of chars that you want to insert inside/outside the current pair.
---if firstChar == lastChar you can omit last char
---```lua
---require("pairMan").PairInserter{'"'}
---```
---is the same as:
---```lua
---require("pairMan").PairInserter{'"', '"'}
---```
---@param motion ("a"|"i") `a` means insert pair outside, `i` means inside.
---if you want to put [] inside (), you would call this while you're on top the pair:
---```lua
---require("pairMan").PairInserter({"(", ")"}, "a")
---```
---@param backwards? boolean if true, backwards search a regex pair.
---some random line: abcd`"`efg`"`hijkl
---you want to insert single qoutes between the double qoutes.
---if your cursor is on the qoute that's between `d` and `e` you can do:
---```lua
---require("pairMan").PairInserter({"'"}, "i")
---```
---but if your cursor is on the qoute that's between `g` and `h`, you need to do:
---```lua
---require("pairMan").PairInserter({"'"}, "i", true)
---```
---@nodoc }}}2
function m.PairInserter(chars, motion, backwards)
    initPairManupulation(chars, backwards)

    if motion == "a" then
        if vim.list_contains(m._firstChars, m._charUnderCursor) then
            simkeys("%a" .. m._chars[2] .. "<ESC>gv<ESC>i" .. m._chars[1])
        elseif vim.list_contains(m._lastChars, m._charUnderCursor) then
            simkeys("%i" .. m._chars[1] .. "<ESC>gvl<ESC>a" .. m._chars[2])
        else
            if vim.list_contains(m._lastChars, m._chars[1]) then
                simkeys(
                    ":lua vim.fn.search('"
                        .. m._regex
                        .. "', 'b')<CR>i"
                        .. m._chars[2]
                        .. "<ESC>gv<ESC>la"
                        .. m._chars[1]
                )
            elseif vim.list_contains(m._firstChars, m._chars[1]) or m._backwards == false then
                simkeys(
                    ":lua vim.fn.search('" .. m._regex .. "')<CR>a" .. m._chars[2] .. "<ESC>gv<ESC>i" .. m._chars[1]
                )
            else
                simkeys(
                    ":lua vim.fn.search('"
                        .. m._regex
                        .. "', 'b')<CR>i"
                        .. m._chars[1]
                        .. "<ESC>gv<ESC>la"
                        .. m._chars[2]
                )
            end
        end
    else
        if vim.list_contains(m._firstChars, m._charUnderCursor) then
            simkeys("%i" .. m._chars[2] .. "<ESC>gv<ESC>a" .. m._chars[1])
        elseif vim.list_contains(m._lastChars, m._charUnderCursor) then
            simkeys("%a" .. m._chars[1] .. "<ESC>gvl<ESC>i" .. m._chars[2])
        else
            if vim.list_contains(m._lastChars, m._chars[1]) then
                simkeys(
                    ":lua vim.fn.search('"
                        .. m._regex
                        .. "', 'b')<CR>a"
                        .. m._chars[2]
                        .. "<ESC>gv<ESC>li"
                        .. m._chars[1]
                )
            elseif vim.list_contains(m._firstChars, m._chars[1]) or m._backwards == false then
                simkeys(
                    ":lua vim.fn.search('" .. m._regex .. "')<CR>i" .. m._chars[2] .. "<ESC>gv<ESC>a" .. m._chars[1]
                )
            else
                simkeys(
                    ":lua vim.fn.search('"
                        .. m._regex
                        .. "', 'b')<CR>a"
                        .. m._chars[1]
                        .. "<ESC>gv<ESC>li"
                        .. m._chars[2]
                )
            end
        end
    end
    simkeys("<ESC>")
end -- }}}1

---@nodoc setup() {{{
---@nodoc docs {{{
---### calls the setup. you need to specify at least one of opts.
---@param opts {keymap:string?, changerKeymap:string?, inserterKeymap:string?, buflocal:boolean?} opts:
---`keymap:` sets both the `changerKeymap` and the `inserterKeymap` prefix
---`changerKeymap:` sets the prefix for pair changer keymaps. that means changing [] to (), etc.
---`inserterKeymap:` sets the prefix for pair inserter keymaps. that means inserting [] inside/outside ()
---
---If you're using the leader key in any of these, be sure that the leader key is set up before calling this function.
---
---`buflocal:` If true, make the keymaps local to the current buffer. also the current buffer's |matchpairs| option is
---read.
---If buflocal not true, it makes keymaps globally, and reads the global matchpairs option.
---
---For most people it would be enough, but |matchpairs| itself can be set locally for buffers.
---If you set your c files to match <:> via:
---```lua
---vim.opt_local.matchpairs = "(:),{:},[:],<:>"
---```and if buflocal isn't true, this plugin won't work with <:>.
---
---to fix this, you either need to add <:> globally, or call this setup in an |autocommand| or a |filetype-plugin|.
---
---i tried to make an option where the setup would create an autocommand, and when you enter a buffer, it reads the
---current matchpairs option, and set the keymaps accordingly, but it was causing a lot of issues. i'm not a neovim
---expert, so i currently don't know how to do it. but i'll try.
---@nodoc docs }}}
function m.setup(opts)
    if opts.keymap ~= nil then
        opts.changerKeymap = opts.keymap
        opts.inserterKeymap = opts.keymap
    end

    local firstChars, lastChars = returnMatchPairs(true)
    local bufvalue = false

    if opts.buflocal == true then
        bufvalue = true
        firstChars, lastChars = returnMatchPairs(false)
    end

    if opts.changerKeymap ~= nil then -- {{{
        vim.keymap.set("n", opts.changerKeymap .. "x", function()
            m.PairChanger()
        end, { desc = "remove % pair", buffer = bufvalue })
        for i = 1, #firstChars do
            vim.keymap.set("n", opts.changerKeymap .. firstChars[i], function()
                m.PairChanger { firstChars[i], lastChars[i] }
            end, { desc = "Change pair to " .. firstChars[i] .. lastChars[i], buffer = bufvalue })

            vim.keymap.set(
                "n",
                opts.changerKeymap .. lastChars[i],
                function()
                    m.PairChanger { lastChars[i], firstChars[i] }
                end,
                { desc = "Change pair to " .. firstChars[i] .. lastChars[i] .. " if on last qoute", buffer = bufvalue }
            )
        end

        vim.keymap.set("n", opts.changerKeymap .. '"', function()
            m.PairChanger { '"' }
        end, { desc = 'Change % pair to ""', buffer = bufvalue })

        vim.keymap.set("n", opts.changerKeymap .. "'", function()
            m.PairChanger { "'" }
        end, { desc = "Change % pair to ''", buffer = bufvalue })

        vim.keymap.set("n", opts.changerKeymap .. 'h"', function()
            m.PairChanger({ '"' }, true)
        end, { desc = 'Change qoute to "". needs to be on last', buffer = bufvalue })

        vim.keymap.set("n", opts.changerKeymap .. "h'", function()
            m.PairChanger({ "'" }, true)
        end, { desc = "Change qoute to ''. needs to be on last", buffer = bufvalue })

        vim.keymap.set("n", opts.changerKeymap .. "hx", function()
            m.PairChanger(nil, true)
        end, { desc = "Deletes a qoute. needs to be on last", buffer = bufvalue })
    end --}}}

    if opts.inserterKeymap ~= nil then --{{{
        for i = 1, #firstChars do
            vim.keymap.set("n", opts.inserterKeymap .. "a" .. firstChars[i], function()
                m.PairInserter({ firstChars[i], lastChars[i] }, "a")
            end, { desc = "Put " .. firstChars[i] .. lastChars[i] .. " around pair", buffer = bufvalue })

            vim.keymap.set(
                "n",
                opts.inserterKeymap .. "a" .. lastChars[i],
                function()
                    m.PairInserter({ lastChars[i], firstChars[i] }, "a")
                end,
                { desc = "Put " .. firstChars[i] .. lastChars[i] .. " around pair if on last qoute", buffer = bufvalue }
            )

            vim.keymap.set("n", opts.inserterKeymap .. "i" .. firstChars[i], function()
                m.PairInserter({ firstChars[i], lastChars[i] }, "i")
            end, { desc = "Put " .. firstChars[i] .. lastChars[i] .. " inside pair", buffer = bufvalue })

            vim.keymap.set(
                "n",
                opts.inserterKeymap .. "i" .. lastChars[i],
                function()
                    m.PairInserter({ lastChars[i], firstChars[i] }, "i")
                end,
                { desc = "Put " .. firstChars[i] .. lastChars[i] .. " inside pair if on last qoute", buffer = bufvalue }
            )
        end

        vim.keymap.set("n", opts.inserterKeymap .. 'a"', function()
            m.PairInserter({ '"' }, "a")
        end, { desc = 'Put "" around % pair', buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. "a'", function()
            m.PairInserter({ "'" }, "a")
        end, { desc = "Put '' around % pair", buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. 'ah"', function()
            m.PairInserter({ '"' }, "a", true)
        end, { desc = 'Put "" around pair if on last qoute', buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. "ah'", function()
            m.PairInserter({ "'" }, "a", true)
        end, { desc = "Put '' around pair if on last qoute", buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. 'i"', function()
            m.PairInserter({ '"' }, "i")
        end, { desc = 'Put "" inside pair', buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. "i'", function()
            m.PairInserter({ "'" }, "i")
        end, { desc = "Put '' inside pair", buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. 'ih"', function()
            m.PairInserter({ '"' }, "i", true)
        end, { desc = 'Put "" inside pair if on last qoute', buffer = bufvalue })

        vim.keymap.set("n", opts.inserterKeymap .. "ih'", function()
            m.PairInserter({ "'" }, "i", true)
        end, { desc = "Put '' inside pair if on last qoute", buffer = bufvalue })
    end --}}}
end -- }}}

return m
