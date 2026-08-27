--------------------------------------------------------------------------------
-- Icons
--
-- Copied verbatim from github.com/ayamir/nvimdots, licensed under
-- the BSD 3-Clause License:
--
--   Copyright (c) 2021 ayamir
--   Copyright (c) 2022 Jint-lzxy, CharlesChiuGit
--   Copyright (c) 2023 aarnphm, misumisumi
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
-- 3. Neither the name of the copyright holder nor the names of its
--    contributors may be used to endorse or promote products derived from
--    this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
local M = {}

local data = {
  kind = {
    Break = '󰙧',
    Call = '󰃷',
    Case = '󰬶',
    Class = '󰠱',
    Color = '󰏘',
    Constant = '󰏿',
    Constructor = '',
    Continue = '󰞘',
    Declaration = '󰙠',
    Delete = '󱟁',
    Enum = '',
    EnumMember = '',
    Event = '',
    Field = '󰇽',
    File = '󰈙',
    Folder = '󰉋',
    Fragment = '',
    Function = '󰊕',
    Implementation = '',
    Interface = '',
    Keyword = '󰌋',
    List = '󰅪',
    Loop = '󰑖',
    Method = '󰆧',
    Module = '',
    Namespace = '󰌗',
    Operator = '󰆕',
    Package = '',
    Property = '󰜢',
    Reference = '',
    Regex = '',
    Snippet = '',
    Statement = '󰅩',
    Struct = '',
    Switch = '',
    Text = '󰉿',
    TypeParameter = '󰅲',
    Undefined = '',
    Unit = '',
    Value = '󰎠',
    Variable = '',
    -- ccls-specific icons
    Macro = '',
    Parameter = '',
    StaticMethod = '',
    Terminal = '',
    TypeAlias = '',
  },
  type = {
    Array = '󰅪',
    Boolean = '',
    Null = '󰟢',
    Number = '',
    Object = '󰅩',
    String = '󰉿',
  },
  documents = {
    Default = '',
    File = '',
    Files = '',
    FileFind = '󰈞',
    FileTree = '󰙅',
    Import = '',
    Symlink = '',
    Word = '',
  },
  git = {
    Add = '',
    Branch = '',
    Diff = '',
    Git = '󰊢',
    Ignore = '',
    Mod = 'M',
    Mod_alt = '',
    Remove = '',
    Rename = '',
    Repo = '',
    Unmerged = '󰘬',
    Untracked = '󰞋',
    Unstaged = '',
    Staged = '',
    Conflict = '',
  },
  ui = {
    Accepted = '',
    ArrowClosed = '',
    ArrowOpen = '',
    ArrowRight = '󰁔',
    BigDot = '',
    BookMark = '󰃃',
    Buffer = '󰓩',
    Bug = '',
    Calendar = '',
    Character = '',
    Check = '󰄳',
    ChevronRight = '',
    Circle = '',
    Close = '󰅖',
    Close_alt = '',
    CloudDownload = '',
    CodeAction = '󰌵',
    Comment = '󰅺',
    Dashboard = '',
    Dot = '',
    DoubleSeparator = '󰄾',
    Emoji = '󰱫',
    EmptyFolder = '',
    EmptyFolderOpen = '',
    File = '󰈤',
    Fire = '',
    Folder = '',
    FolderOpen = '',
    FolderWithHeart = '󱃪',
    Gear = '',
    History = '󰄉',
    Incoming = '󰏷',
    Indicator = '',
    Keyboard = '',
    Left = '',
    List = '',
    Lock = '󰍁',
    MiddleDot = '●',
    Modified = '✥',
    Modified_alt = '',
    NewFile = '',
    Newspaper = '',
    Note = '󰍨',
    Outgoing = '󰏻',
    Package = '',
    Pencil = '󰏫',
    Perf = '󰅒',
    Play = '',
    Project = '',
    Right = '',
    RootFolderOpened = '',
    Search = '󰍉',
    Separator = '',
    SmallDot = '•',
    SignIn = '',
    SignOut = '',
    Sort = '',
    Spell = '󰓆',
    Square = '',
    Symlink = '',
    SymlinkFolder = '',
    Tab = '',
    Table = '',
    Telescope = '',
    Window = '',
  },
  diagnostics = {
    Error = '',
    Warning = '',
    Information = '',
    Question = '',
    Hint = '󰌵',
    -- Hollow version
    Error_alt = '󰅚',
    Warning_alt = '󰀪',
    Information_alt = '',
    Question_alt = '',
    Hint_alt = '󰌶',
  },
  misc = {
    Add = '+',
    Added = '',
    Campass = '󰀹',
    Code = '',
    Gavel = '',
    Ghost = '󰊠',
    Glass = '󰂖',
    Lego = '',
    LspAvailable = '󰒋',
    ManUp = '',
    Neovim = '',
    NoActiveLsp = '󰒏',
    PyEnv = '󰢩',
    Squirrel = '',
    Tag = '',
    Tree = '',
    Vbar = '│',
    Vim = '',
    Watch = '',
  },
  cmp = {
    buffer = '󰉿',
    copilot = '',
    copilot_alt = '',
    latex_symbols = '',
    luasnip = '󰃐',
    nvim_lsp = '',
    path = '',
    spell = '󰓆',
    tmux = '',
    treesitter = '',
    undefined = '',
  },
  dap = {
    Breakpoint = '󰝥',
    BreakpointCondition = '󰟃',
    BreakpointRejected = '',
    LogPoint = '',
    Pause = '',
    Play = '',
    RunLast = '↻',
    StepBack = '',
    StepInto = '󰆹',
    StepOut = '󰆸',
    StepOver = '󰆷',
    Stopped = '',
    Terminate = '󰝤',
  },
  aichat = {
    Chat = '󱜸',
    Copilot = '',
    Me = '',
  },
}

---Get a specific icon set.
---@param category "kind"|"type"|"documents"|"git"|"ui"|"diagnostics"|"misc"|"cmp"|"dap"|"aichat"
---@param add_space? boolean @Add trailing whitespace after the icon.
function M.get(category, add_space)
  if add_space then
    return setmetatable({}, {
      __index = function(_, key)
        return data[category][key] .. ' '
      end,
    })
  else
    return data[category]
  end
end

return M
