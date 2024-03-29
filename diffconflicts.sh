#!/bin/bash
# Use *real* vimdiff to edit merge conflicts in Git
#
# Instead of editing a file with <<<< ==== >>> conflict markers, this opens
# each "side" of the conflict markers in a two-way vimdiff window.
#
# (I'm not clear why this isn't the default behavior for Git's vimdiff
# mergetool script. What purpose does the 'result' window with the conflict
# markers serve that vimdiff can't do better on its own?)
#
# Layout:
#
# Tab1 is a two-way diff of the conflicts.
# +--------------------------------+
# | LCONFL | RCONFL |
# +--------------------------------+
# Tab2 is a three-way diff of the original files and the merge base.
# +--------------------------------+
# | LOCAL | BASE | REMOTE |
# +--------------------------------+
# Tab3 is the MERGED or 'result' file that contains the conflict markers.
# +--------------------------------+
# | <<<<<<< HEAD |
# | LCONFL |
# | ======= |
# | RCONFL |
# | >>>>>>> someref |
# +--------------------------------+
#
# Workflow:
#
# 1. Save your changes to the LCONFL temporary file (the left window on the
# first tab; also the only file that isn't read-only).
# 2. The LOCAL, BASE, and REMOTE versions of the file are available in the
# second tabpage if you want to look at them.
# 3. When vimdiff exits cleanly, the file containing the conflict markers
# will be updated with the contents of your LCONFL file edits.
#
# NOTE: Use :cq to abort the merge and exit Vim with an error code.
#
# Add this mergetool to your ~/.gitconfig (you can substitute gvim for vim):
#
# git config --global merge.tool diffconflicts
# git config --global mergetool.diffconflicts.cmd 'diffconflicts vim $BASE $LOCAL $REMOTE $MERGED'

# git config --global mergetool.diffconflicts.trustExitCode true
# git config --global mergetool.diffconflicts.keepBackup false

if [[ -z $@ || $# != "5" ]] ; then
echo -e "Usage: $0 \$EDITOR \$BASE \$LOCAL \$REMOTE \$MERGED"
    exit 1
fi

cmd=$1
BASE=$2
LOCAL=$3
REMOTE=$4
MERGED=$5

# Temporary files for left and right side
# LCONFL=$MERGED.REMOTE.$$.tmp
# RCONFL=$MERGED.LOCAL.$$.tmp
RCONFL=$MERGED.REMOTE.$$.tmp
LCONFL=$MERGED.LOCAL.$$.tmp

# Always delete our temp files; Git will handle it's own temp files
trap 'rm -f '$LCONFL' '$RCONFL SIGINT SIGTERM EXIT

# Remove the conflict markers for each 'side' and put each into a temp file
# sed -e '/^<<<<<<< /,/^=======$/d' -e '/^>>>>>>> /d' $MERGED > $LCONFL
# sed -e '/^=======$/,/^>>>>>>> /d' -e '/^<<<<<<< /d' $MERGED > $RCONFL
sed -e '/^<<<<<<< /,/^=======$/d' -e '/^>>>>>>> /d' $MERGED > $LCONFL
sed -e '/^||||||| /,/^>>>>>>> /d' -e '/^<<<<<<< /d' $MERGED > $RCONFL

# Fire up vimdiff

$cmd -f -R -d $LCONFL $RCONFL \
	-c ":set noro" \
	-c ":winc t" \
	-c ":tabe $MERGED" \
	-c ":diffs $REMOTE" \
	-c ":vert diffs $BASE" \
	-c ":vert diffs $LOCAL" \
	-c ":tabfir"

EC=$?

# Overwrite $MERGED only if vimdiff exits cleanly.
if [[ $EC == "0" ]] ; then
cat $LCONFL > $MERGED
fi

exit $EC
