CONCEALER
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Ever tried exploring a log file or complex configuration, and struggling to
distinguish between 58343925-ae76-41f5-bf6e-4048484d9a5f and
58343925-ae77-41f5-bf6e-404848489a5f, or trying to see the gist among 128-char
security token monsters, IPv6 addresses, object IDs?

This plugin adds mappings and commands to conceal the current word, selection,
or regular expression pattern matches on the fly. Either globally, or just
inside the current window, each concealed text is condensed to a single
special character (or hidden completely).
Via [count], additional alternatives can be added / removed to the global
conceal groups; the window-local groups instead allow quick and easy toggling.
Since the text is only concealed, this doesn't touch the actual buffer
contents, can be toggled on/off, and as a bonus there's even a command to list
all defined groups and active patterns.

### HOW IT WORKS

This plugin is based on the conceal feature introduced in Vim 7.3.

### SEE ALSO

- mark.vim ([vimscript #2666](http://www.vim.org/scripts/script.php?script_id=2666)) also offers mappings and commands to highlight,
  not conceal, several patterns in different colors simultaneously.
  If you just want to differentiate multiple patterns (without shrinking their
  visual representation), use this plugin.
- SearchAlternatives.vim ([vimscript #4146](http://www.vim.org/scripts/script.php?script_id=4146)) can also add and subtract
  alternatives via mappings and commands, but to the search pattern, not
  different conceal groups.
- FoldCol (http://www.drchip.org/astronaut/vim/index.html#FOLDCOL) can fold
  away a blockwise visual selection in a buffer.

USAGE
------------------------------------------------------------------------------

    The Concealer offers both global and buffer-local hiding of certain text /
    regular expression matches. The former works like search highlighting; it
    applies to each buffer in every open window. The latter is only defined for
    the current buffer, and conceal defaults are only applied to the current
    window, so even window splits of the same buffer won't show a difference until
    you enable concealing in those windows, too.

    Global concealing offers finer control, using [count] to add and remove
    alternatives to the conceal group. Use it to create long-lived highlights and
    multi-buffer investigations. On the other hand, buffer-local concealing is
    accessible via a single simple toggle mapping, and is just right when you want
    to quickly get rid of a particular text fragment right there and now.

    {Visual}[count]<Leader>X+
    [count]<Leader>X+       Globally conceal the current whole \<word\> (similar
                            to the star command) / the selected text.
                            Without [count], the next free conceal group is used.
                            With [count], adds the pattern to the conceal group
                            [count] instead.
                            Concealment applies to all buffers. To conceal only in
                            the current buffer, use <Leader>XX.

    <Leader>X-              Stop concealing the current whole \<word\> / selected
    {Visual}<Leader>X-      text everywhere. Also removes this alternative from
                            any conceal group that contains it.
    [count]<Leader>X-       Stop concealing (all patterns in) conceal group
                            [count].
    {Visual}<Leader>X-

    <Leader>XX              In the current buffer, toggle concealing the current
                            whole \<word\> (similar to the star command) / the
                            selected text.
                            Without [count], the next free conceal group is used.
                            Concealment only applies to the current buffer. To
                            conceal globally in all buffers, or to selectively
                            add or remove patterns to individual conceal groups,
                            use <Leader>X+ / <Leader>X-.
                            To remove all buffer-local conceal groups, you can use
                            :ConcealHere!.

    :[count]ConcealHere {expr}
                            In the current buffer, conceal {expr}.
                            Without [count], the next free conceal group is used.
                            With [count], uses conceal group [count] instead (and
                            clears any text previously concealed by that group).
                            Concealment only applies to the current buffer. To
                            conceal globally in all buffers, or to selectively
                            remove patterns or individual conceal groups, use
                            :ConcealAdd / :ConcealRemove.
    :[count]ConcealHere!    In the current buffer, stop concealing local group
                            [count] / all local groups defined by :ConcealHere
                            and <Leader>XX.
    :[count]ConcealHere! {expr}
                            In the current buffer, toggle concealing {expr}: If
                            a / the conceal group [count] contains {expr}, it is
                            cleared; else, it starts concealing {expr}.

    :[count]ConcealAdd {expr}
                            Globally conceal {expr}.
                            Without [count], the next free conceal group is used.
                            With [count], adds the pattern to the conceal group
                            [count] instead.
                            Concealment applies to all buffers. To conceal only in
                            the current buffer, use :ConcealHere.

    :ConcealRemove {expr}   Stop concealing {expr} everywhere.
    :[count]ConcealRemove   Stop concealing any patterns in conceal group [count].
    :ConcealRemove!         Stop concealing anything by any global conceal group.

    :Conceals               List all conceal groups and the patterns defined for
                            them. The group number (for use as [count]), conceal
                            character and pattern are listed.
                            Unless there are buffer-local conceals, all global
                            groups are always listed (even when empty) so that you
                            can easily choose a proper group for easier recall.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-Concealer
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim Concealer*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.3 or higher with the +conceal feature.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.043 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

For the first 11 conceal groups, different conceal characters (:syn-cchar)
are preset to allow easy recognition of the concealed areas. All additional
groups get the default conceal character defined in the 'listchars' option, or
are completely hidden, depending on 'conceallevel').

As conceal characters, when possible, special characteristic Unicode
characters are choosen. To change the set or number of characters:

    let g:Concealer_Characters_Global = '!@#$%^&*()_'
    let g:Concealer_Characters_Local = '1234567890_'

By default, concealing is off; but Concealer automatically presets
'conceallevel' when conceal groups are used, so that you immediately see the
effects without manually reconfiguring concealment. This preset is applied
only to the current window for local conceal groups, and to all windows once
there have been global conceal groups. To disable the default preset:

    let g:Concealer_ConcealLevel = 0

To completely hide the text, without conceal char:

    let g:Concealer_ConcealLevel = 3

Likewise, to change the 'concealcursor' preset:

    let g:Concealer_ConcealCursor = 'nv'

INTEGRATION
------------------------------------------------------------------------------

You can use the following functions to define custom, buffer-local
concealments.
- Concealer#AddLocal({key}, {char}, {pattern})
- Concealer#RemoveLocal({key})
- Concealer#Here({isSilent}, {isCommand}, {isBang}, {key}, {pattern}, {char})
- Concealer#ToggleLiteralHere({key}, {text}, {isWholeWordSearch}, {char})

These support a custom {char}. Choose a non-numeric, alphabetic {key} to avoid
interfering with the conceal groups defined by the plugin. If you include an
underscore character, the definition will be hidden from the :Conceals
output.

LIMITATIONS
------------------------------------------------------------------------------

- As the conceal feature is bound to the syntax highlighting, the original
  filetype's syntax may interfere with Concealer, and vice versa. A workaround
  is to temporarily turn off the filetype's syntax either locally
 <!-- -->

    :setl syn=

  or globally

    :syntax off

### KNOWN PROBLEMS

- After :syntax off and :syntax on, the conceals aren't automatically
  reinstated after a change of 'syntax'.

### CONTRIBUTING

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-Concealer/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### GOAL
First published version.

##### 0.01    24-Jul-2012
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2012-2021 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
