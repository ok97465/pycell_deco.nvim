# pycell_deco.nvim

## Overview

This plugin draws a line and changes a font color for python cell (# %%).

- This is using a lot of code of lukas-reineke/headlines.nvim

![DEMO](/doc/demo.gif)

## Installation

```vim
Plug 'ok97465/pycell_deco.nvim'
```

## Configuration

```lua
require("pycell_deco").setup{cell_name_fg="#1abc9c", cell_line_bg=nil}
```
