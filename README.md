# pycell_deco.nvim

## Overview

This plugin draws a dash line and highlights Python cell headers (`# %%`).

- This is using a lot of code of lukas-reineke/headlines.nvim

![DEMO](/doc/demo.gif)

## Requirements

- Neovim 0.11+

## Installation

```vim
Plug 'ok97465/pycell_deco.nvim'
```

## Configuration

```lua
require("pycell_deco").setup{
  -- Single color used for header, cell name and dash
  color = "#1abc9c",
}
```
