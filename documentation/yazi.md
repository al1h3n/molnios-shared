# _[MolniOS](https://codeberg.org/al1h3n/molnios-install)_ yazi keybinds:
The syntax is kinda like `nvim`.<br>
`<C-a>` = `Ctrl+A`.<br>

### Navigating
`F1 ~` - help window with all keybinds.<br>
`ESC` - escape from any window.<br>
Navigate with arrows `hjkl`.<br>
`Back/forward` - `HL`.<br>
To move cursor further use `Pg Up/Down`.<br>
`gg`|`G` - top | bottom.<br>
`f` - filter files (regular search, don't forget to clean it).<br>
`/ ?` - create find request. Use `n N` to navigate.<br>

### Sorting `,`
`a` - alphabetically.<br>
`m` - by modified time.<br>
`e` - by extension.<br>
`s` - by size.<br>

### Goto `g`
`d` - `~/Downloads`<br>
`h` - `~`<br>
`c` - `~/.config`<br>

### Tabs
`t` - create a tab. Navigate via numbers or `[]`.<br>
`Ctrl+C` - close a tab.<br>
`{}` - switch tabs with nearest one.<br>

### Modes
`v` `V` - select/unselect mode (VISUAL).<br>

### Selection
`Space` - select or unselect a file.<br>
`Ctrl+R` - select or unselect all files.<br>

### Main keybinds
`q` - quit from yazi.<br>
`c` - copy menu.<br>

### Copy menu
`cd` - copy __directory__ path.<br>
`cc` - copy file path.<br>

### Preview
`K J` - move up/down in preview.<br>

### Operations
`o Enter` `O Shift+Enter` - open folder in shell, open interative menu (open/metadata).<br>
`y Y` `x X` - (un)copy/cut files.<br>
`p P` - paste files (`P` - override).<br>
`- _` - symlink absolute/relative paths of yanked files (works as paste symlink).<br>
`d D` - delete files (`D` - permanently).<br>
`a` - create file (type `/` at the end to make dir, type `x/y` to create dir in dir).<br>
`r` - rename file.<br>
`; :` - run shell command (`:` - don't leave until finish).<br>
`s S` - search by name/content in files.<br>
`Ctrl+s` - cancel search.<br>
`z Z`- go to file via `fzf` (all files), `zoxide` (most used files).<br>

### Linemode (additional information on right side of file).
`m` - open linemode selection.<br>
