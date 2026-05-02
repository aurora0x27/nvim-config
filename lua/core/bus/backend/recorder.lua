--------------------------------------------------------------------------------
-- Recorder backend -- for fzf support
--------------------------------------------------------------------------------

---@class MsgRecorderOpt
---@field max_msg_limit? integer

local calculate_layout = require 'utils.render'.calculate_layout

local M = {}

local RecordedMessages = {}

local MessagePreviewer = nil

local PREVIEW_TITLE = ' RecordedMsg '

---@type MsgRecorderOpt
local MSG_RECORDER_OPT_DEFAULT = {
    max_msg_limit = 1024,
}

local Opt = vim.deepcopy(MSG_RECORDER_OPT_DEFAULT)

local function make_previewer()
    local Previewer = require 'fzf-lua.previewer.builtin'

    if MessagePreviewer then
        return MessagePreviewer
    end

    local P = Previewer.buffer_or_file:extend()

    function P:new(o, opts, fzf_win)
        P.super.new(self, o, opts, fzf_win)
        self.title = PREVIEW_TITLE
        setmetatable(self, P)
        return self
    end

    function P:parse_entry(entry_str)
        local idx = tonumber(entry_str:match('^%[(%d+)%]'))
        local entry = RecordedMessages[idx]
        return entry
    end

    function P:populate_preview_buf(entry_str)
        local tmpbuf = self:get_tmp_buffer()
        local msg = self:parse_entry(entry_str)
        if not msg then
            return
        end
        if type(msg.content) == 'string' then
            local lines = vim.split(msg.content, '\n', { plain = true })
            vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
        else
            local layout = calculate_layout(msg.content)
            vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, layout.lines)
            local ns = vim.api.nvim_create_namespace('fzf_msg_preview')
            vim.api.nvim_buf_clear_namespace(tmpbuf, ns, 0, -1)
            for _, m in ipairs(layout.marks) do
                pcall(
                    vim.api.nvim_buf_set_extmark,
                    tmpbuf,
                    ns,
                    m.row,
                    m.col_start,
                    {
                        end_col = m.col_end,
                        hl_group = m.hl,
                        priority = 100,
                    }
                )
            end
        end
        self:set_preview_buf(tmpbuf)
        self.win:update_preview_title(PREVIEW_TITLE)
        self.win:update_preview_scrollbar()
    end

    MessagePreviewer = P
    return MessagePreviewer
end

function M.fzf_messages()
    local Fzf = require 'fzf-lua'

    local contents = {}

    for i, msg in ipairs(RecordedMessages) do
        local time_str = os.date('%H:%M:%S', math.floor(msg.timestamp / 1000))

        local summary
        if type(msg.content) == 'string' then
            summary = msg.content
        else
            local layout = calculate_layout(msg.content)
            summary = layout.lines[1]:gsub('\n', ' '):sub(1, 80)
        end

        table.insert(
            contents,
            string.format(
                '[%d] %s │ %-10s │ %s',
                i,
                time_str,
                msg.tag:gsub('msg.show.', ''),
                summary
            )
        )
    end

    contents = vim.fn.reverse(contents)

    Fzf.fzf_exec(contents, {
        prompt = '> ',
        previewer = make_previewer(),
        actions = {
            ['default'] = function(selected)
                local idx = tonumber(selected[1]:match('^%[(%d+)%]'))
                local msg = RecordedMessages[idx]
                if msg then
                    if type(msg.content) == 'string' then
                        print(msg.content)
                    else
                        local layout = calculate_layout(msg.content)
                        print(table.concat(layout.lines, '\n'))
                    end
                end
            end,
            ['ctrl-y'] = function(selected)
                local idx = tonumber(selected[1]:match('^%[(%d+)%]'))
                local msg = RecordedMessages[idx]
                if type(msg.content) == 'string' then
                    vim.fn.setreg('+', msg.content)
                else
                    local layout = calculate_layout(msg.content)
                    vim.fn.setreg('+', table.concat(layout.lines, '\n'))
                end
                print('Copied to clipboard')
            end,
        },
        winopts = {
            wrap = true,
            title = ' Messages ',
        },
        fzf_opts = {
            ['--delimiter'] = ' ',
            ['--with-nth'] = '2..',
            ['--tiebreak'] = 'index',
        },
    })
end

function M.clear()
    vim.notify(
        'All the messages cleared',
        vim.log.levels.INFO,
        { title = 'Message Recorder' }
    )
    RecordedMessages = {}
end

---@param opts? MsgRecorderOpt
function M.setup(opts)
    Opt = vim.tbl_deep_extend('force', Opt, opts or {})
    Bus.register_subscriber(
        'recorder',
        {
            exact = {
                'notify',
                'bus',
                'msg.clear',
                'msg.show.emsg',
                'msg.show.echoerr',
                'msg.show.echo',
                'msg.show.echomsg',
                'msg.show.lua_error',
                'msg.show.lua_print',
                'msg.show.rpc_error',
                'msg.show.shell_out',
                'msg.show.shell_ret',
                'msg.show.shell_err',
                'msg.show.bufwrite',
                'msg.show.quickfix',
            },
        },
        vim.log.levels.TRACE,
        function(msg)
            if msg.tag == 'msg.clear' then
                M.clear()
                return false
            end
            if #RecordedMessages > Opt.max_msg_limit then
                table.remove(RecordedMessages, 1)
            end
            table.insert(RecordedMessages, msg)
            return false
        end
    )

    vim.api.nvim_create_user_command('MessageClear', M.clear, {})
end

return M
