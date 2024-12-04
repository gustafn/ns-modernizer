#!/usr/bin/env tclsh
#
# This script helps identify and optionally replace deprecated
# NaviServer calls with their updated equivalents.
#
# Caution: Do not rely on this script blindly; review its changes as
# it serves as a helper tool, not a definitive solution.
#
# When the script is executed, it checks all "*tcl" files in the current
# directory tree and replaces deprecated calls with non-deprecated
# ones. The original files are preserved with a "-original" suffix.
#
# Basic Usage:
#  - run "tclsh ns-modernizer.tcl -cd YOUR_TCL_FILE_TREE"
#
#    Example:
#        tclsh ns-modernizer.tcl -cd /usr/local/oacs-head/openacs-4/packages/
#
# Slightly Advanced usage:
#  - Perform updates
#       tclsh ns-modernizer.tcl -change 1

#  - List the differences
#       tclsh ns-modernizer.tcl -diff 1
#
#  - Undo tue changes of a run
#       tclsh ns-modernizer.tcl -reset 1 -change 0
#
#  - Reset the changes and run the script again
#       tclsh ns-modernizer.tcl -reset 1 -change 1
#
#  - Remove the -original files after a run to avoid name clashes
#       rm `find . -name \*original`
#
# Gustaf Neumann,   Nov 2024
#
array set opt {-cd . -reset 0 -change 0 -diff 0 -path . -name *tcl}
array set opt $argv

cd $opt(-cd)
puts "working directory is [pwd]"

if {$opt(-reset)} {
    foreach file [exec find -L $opt(-path) -type f -name *-original] {
        regexp {^(.*)-original} $file _ new
        file delete $new
        file rename $file $new
    }
}
if {$opt(-diff)} {
    foreach file [exec find -L $opt(-path) -type f -name *-original] {
        regexp {^(.*)-original} $file _ new
        set status [catch {exec diff -wu $file $new} result]
        puts "---diff -wu $file $new"
        puts $result
    }
    exit
}

set tbd {
}

set deprecated {
    "ns_browsermatch"
    "ns_choosecharset"
    "ns_cookiecharset"
    "ns_formfieldcharset"
    "ns_formvalueput"
    "ns_paren"
    "ns_tagelement"
    "ns_tagelementset"

    "Paren"
    "env"
    "getformdata"
    "issmallint"
    "ns_adp_compress"
    "ns_adp_eval"
    "ns_adp_mime"
    "ns_adp_registertag"
    "ns_adp_safeeval"
    "ns_adp_stream"
    "ns_cancel"
    "ns_checkurl"
    "ns_chmod"
    "ns_conncptofp"
    "ns_connsendfp"
    "ns_cp"
    "ns_cpfp"
    "ns_db verbose"
    "ns_event"
    "ns_getchannels"
    "ns_geturl"
    "ns_hmac_sha2"
    "ns_httpget"
    "ns_httpopen"
    "ns_httppost"
    "ns_ictl oncleanup"
    "ns_ictl oncreate"
    "ns_ictl ondelete"
    "ns_ictl oninit"
    "ns_info filters"
    "ns_info pagedir"
    "ns_info pageroot"
    "ns_info platform"
    "ns_info requestprocs"
    "ns_info tcllib"
    "ns_info traces"
    "ns_info url2file"
    "ns_info winnt"
    "ns_isformcached"
    "ns_limits_get"
    "ns_limits_list"
    "ns_limits_register"
    "ns_limits_set"
    "ns_link"
    "ns_mkdir"
    "ns_parsetime"
    "ns_passwordcheck"
    "ns_pooldescription"
    "ns_puts"
    "ns_register_adptag"
    "ns_rename"
    "ns_resetcachedform"
    "ns_returnadminnotice"
    "ns_rmdir"
    "ns_server keepalive"
    "ns_set new"
    "ns_set print"
    "ns_set_precision"
    "ns_sha2"
    "ns_startcontent"
    "ns_subnetmatch"
    "ns_thread begin"
    "ns_thread begindetached"
    "ns_thread get"
    "ns_thread getid"
    "ns_thread join"
    "ns_tmpnam"
    "ns_unlink"
    "ns_unregister_proc"
    "ns_updateheader"
    "ns_var"
    "ns_writecontent"
}

set toBeModernized {
    "ns_set icput"
    "ns_set idelkey"
    "ns_set ifind"
    "ns_set iget"
    "ns_set imerge"
    "ns_set iunique"
}

proc reportFilenameOnce {line} {
    if {!$::filenameReported} {
        puts $line
        set ::filenameReported 1
    }
}

set totalchanges 0
set files 0
foreach file [exec find -L $opt(-path) -type f -name $opt(-name)] {
    #puts "----- working on $file"
    set F [open $file]; set c [read $F]; close $F
    set commandList {}
    set ::filenameReported 0

    #
    # Commands of the form ....[ns...]
    #
    set commands [lsort -unique [lmap {. content} [regexp -all -inline {\[\s*(ns[a-z_]+)\s*\]} $c] {set content}]]
    if {[llength $commands] > 0} {
        #puts brack-1word-commands=$commands
        lappend commandList {*}$commands
    }
    #
    # Commands of the form ....[ns... -|$|[|"]
    #
    set commands [lsort -unique [lmap {. content} [regexp -all -inline {[\n\[]\s*(ns[a-z_]+)\s*[-\$\[\"]} $c] {set content}]]
    if {[llength $commands] > 0} {
        #puts dash-1word-commands=$commands
        lappend commandList {*}$commands
    }
    #
    # Commands of the form ....[ns... xxxx]
    #
    set commands [lmap {. content} [regexp -all -inline {[\n\[]\s*(ns[a-z_]+ +[a-z_]+)\M} $c] {set content}]
    if {[llength $commands] > 0} {
        #puts brace-2word-commands=$commands
        lappend commandList {*}$commands
    }
    #puts commands=$commandList

    foreach cmd [lsort $commandList] {
        if {$cmd in $deprecated} {
            reportFilenameOnce "\n----- [pwd][string trimleft $file .]"
            puts "use of deprecated command: '$cmd'"
        }
    }
    foreach cmd [lsort $commandList] {
        if {$cmd in $tbd} {
            reportFilenameOnce "\n----- [pwd][string trimleft $file .]"
            puts "use of command with unclear future: '$cmd'"
        }
    }

    if {$opt(-change)} {
        set changes 0

        incr changes [regsub -all {ns_adp_mime\M} $c {ns_adp_mimetype} c]
        incr changes [regsub -all {ns_adp_registertag\M} $c {ns_adp_registeradp} c]
        incr changes [regsub -all {ns_cancel\M} $c {ns_unschedule_proc} c]
        incr changes [regsub -all {ns_chmod\s+([a-zA-Z$\"]+) +([0-9]+)\M} $c "file attributes \\1 -permissions \\2" c]
        incr changes [regsub -all {ns_conncptofp\M} $c {ns_conn copy 0 [ns_conn contentlength]} c]
        incr changes [regsub -all {ns_cp\M} $c {file copy} c]
        incr changes [regsub -all {ns_cpfp\M} $c {fcopy} c]
        incr changes [regsub -all {ns_info\s+pageroot\M} $c {ns_server pagedir} c]
        incr changes [regsub -all {ns_info\s+tcllib\M} $c {ns_server tcllib} c]
        incr changes [regsub -all {ns_link\M} $c {file link -hard} c]
        incr changes [regsub -all {ns_mkdir\M} $c {file mkdir} c]
        incr changes [regsub -all {ns_puts\M} $c {ns_adp_puts} c]
        incr changes [regsub -all {ns_register_adptag\M} $c {ns_adp_registerscript} c]
        incr changes [regsub -all {ns_rmdir\M} $c {file delete} c]
        incr changes [regsub -all {ns_server\s+keepalive\M} $c {ns_conn keepalived} c]
        incr changes [regsub -all {ns_set\s+new} $c {ns_set create} c]
        incr changes [regsub -all {ns_subnetmatch\M} $c {ns_ip match} c]
        incr changes [regsub -all {ns_thread\s+get\M} $c {ns_thread handle} c]
        incr changes [regsub -all {ns_thread\s+getid\M} $c {ns_thread id} c]
        incr changes [regsub -all {ns_thread\s+join\M} $c {ns_thread wait} c]
        incr changes [regsub -all {ns_thread\s+start\M} $c {ns_thread create} c]
        incr changes [regsub -all {ns_tmpnam\M} $c {ns_mktemp} c]
        incr changes [regsub -all {ns_unlink\M} $c {file delete} c]
        incr changes [regsub -all {ns_checkurl\M} $c {ns_requestauthorize} c]

        #
        # The following changes could be made automatically as indicated, but the
        # old code predates spooling of received content to a file (and chunked encoding, etc),
        # such that the logic has to be inspected, what's really wanted here. Maybe
        # "ns_getcontent" might be the better choice.
        #
        # incr changes [regsub -all {ns_writecontent\M} $c {ns_conn copy 0 [ns_conn contentlength]} c]
        # incr changes [regsub -all {ns_conncptofp\M} $c {ns_conn copy 0 [ns_conn contentlength]} c]

        # ns_httpget
        # ns_set print

        if {$changes > 0} {
            puts "... updating $file ($changes changes)"
            set F [open /tmp/XXX w]; puts -nonewline $F $c; close $F
            file rename $file $file-original
            set F [open $file w]; puts -nonewline $F $c; close $F
            incr totalchanges $changes
            incr files
        }
    }
}
if {$opt(-change)} {
    puts "$totalchanges changes in $files files"
}
puts \n
