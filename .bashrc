# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
#####################################################################
# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[10;95m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White

######################################################################
# 
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -al'
#alias la='ls -A'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# left hand mouse
# xmodmap -e "pointer = 3 2 1"
#sshfs  murvin@goxv30002638b:/home/murvin/ /home/murvin/net/ 
#sshfs  murvin@goxv30002638b:/mnt/exthd/homebackup/home/murvin/ /mnt/exthd/homebackup/home/murvin
if [ ! -e /mnt/exthd/homebackup/home/murvin ]
then
#  sshfs  murvin@192.168.1.2:/mnt/exthd/homebackup/home/ /mnt/exthd/homebackup/home -o umask=0022
  sshfs  murvin@192.168.1.2:/mnt/exthd/homebackup/home/ /mnt/exthd/homebackup/home
fi

# keyboard schnell
xset r rate 250 50
# mouse schnell
xset m 1 1
# mouse links


## >> MK 201209211035
## >>> GIT-Prompt >>>
## branch != origin/branch
## git log --format=oneline --decorate -1 |grep "(.*origin.*"$(git branch |grep "^\*"|sed -s "s/^\*\s*\(.*\)/\1/")".*)"
function _git_prompt_SAFF() {
    local git_status="`git status -unormal 2>&1`"
    if ! [[ "$git_status" =~ Not\ a\ git\ repo ]]
    then
# white
	fg=37
        if [[ "$git_status" =~ nothing\ to\ commit ]]
	then
# green
            local ansi=32
            local fg=32
        elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]
	then
# brown/yellow
            local ansi=33
	    local fg=33	
        else
# red
#            local ansi=41
            local ansi=31
        fi
        # if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
        #     branch=${BASH_REMATCH[1]}
        #     test "$branch" != master || branch=' '
        # else
        #     # Detached HEAD.  (branch=HEAD is a faster alternative.)
        #     branch="(`git describe --all --contains --abbrev=4 HEAD 2> /dev/null ||
        #         echo HEAD`)"
        # fi
	branch=$(git mk-status)
    	local rem_git_status=$(git log --format=oneline --no-color --decorate -1 |grep "(.*origin.*"$(git branch --no-color|grep "^\*"|sed -s "s/^\*\s*\(.*\)/\1/")".*)" >/dev/null && echo "OK")
	if [ "$rem_git_status" == "OK" ]
	then
	    local rem_fg=$fg
	    local rem_bg=$fg
	else
	    local rem_fg=$fg
	    local rem_bg=41
	fi
	echo -n '\['
	echo -n '\e[0;'"$rem_fg"';'"$rem_bg"'m\]'
	echo -n '['
        echo -n '\['
        echo -n '\e[0;'"$fg"';'"$ansi"';1m\]'
        echo -n "$branch"
	echo -n '\['
	echo -n '\e[0;'"$rem_fg"';'"$rem_bg"'m\]'
	echo -n ']'
	echo -n '\[\e[0m\]'
    fi
}
function _git_prompt() {
    branch=$(git mk-status)
    erg=$?
    if [ "0" == "$erg" ]
    then
	    local git_status="`git status -unormal 2>&1`"
	    if ! [[ "$git_status" =~ Not\ a\ git\ repo ]]
	    then
	# white
		fg=$BWhite
		if [[ "$git_status" =~ nothing\ to\ commit ]]
		then
	# green
		    local ansi=$Green
		    local fg=$Green
		elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]
		then
	# brown/yellow
		    local ansi=$BYellow
		    local fg=$BYellow
		else
	# red
	#            local ansi=41
		    local ansi=$BRed
		fi
		# if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
		#     branch=${BASH_REMATCH[1]}
		#     test "$branch" != master || branch=' '
		# else
		#     # Detached HEAD.  (branch=HEAD is a faster alternative.)
		#     branch="(`git describe --all --contains --abbrev=4 HEAD 2> /dev/null ||
		#         echo HEAD`)"
		# fi
 		local rem_git_status=$(git log --format=oneline --no-color --decorate -1 |grep "(.*origin.*"$(git branch --no-color|grep "^\*"|sed -s "s/^\*\s*\(.*\)/\1/")".*)" >/dev/null && echo "OK")
		if [ "$rem_git_status" == "OK" ]
		then
		    local rem_fg=$fg
		    local rem_bg=$fg
		else
		    local rem_fg=$fg
		    local rem_bg=$On_Red
		fi
		echo -n '\['
		echo -n "$rem_fg$rem_bg"
		echo -n '\]'

		echo -n '['
		echo -n '\[\e[0m\]'

		echo -n '\['
		echo -n "$fg$ansi"
		echo -n '\]'

		echo -n "$branch"
		echo -n '\[\e[0m\]'

		echo -n '\['
		echo -n "$rem_fg$rem_bg"
		echo -n '\]'

		echo -n ']'

		echo -n '\[\e[0m\]'
	    fi
    fi
}
function _prompt_command() {
#    PS1="\u@""`_git_prompt`"'\[\033[01;34m\]\w\[\033[00m\]\$ '
#    PS1="\u@"'\[\033[01;34m\]\w\[\033[00m\]'"`_git_prompt`"'\[\033[00m\]\$ '
    PS1=\
'\n'\
"/-> "\
"`_git_prompt`"\
'\n'\
'\['\
'\033[00m'\
'\]'\
"|   "\
'\['\
"$BBlue"\
'\]'\
'\w'\
'\n'\
'\['\
'\033[00m'\
'\]'\
"\\-> "\
"\u@\h "\
'\$ '
#    echo -ne '\e]2;'$PWD'\007\e]1;\007'
#'... your usual prompt goes here, e.g. \[\e[1;34m\]\w \$\[\e[0m\] '
}

PROMPT_COMMAND=_prompt_command
# <<< GIT-Prompt <<<

# ------------------------------------------------------------------------------ #
# This function sets the title of the terminal-emulator
# or tab.
# ------------------------------------------------------------------------------ #
title() {
    echo -ne "\033]0;${1}\007"
}

export PATH=$PATH:/home/murvin/arbeit/
xmodmap -e "pointer = 1 2 3" 1>/dev/null 2>&1
xmodmap -e "clear lock"
setxkbmap -option caps:none
xset r rate 225 60
xmodmap -e "keycode 66 = Shift_L NoSymbol Shift_L"
