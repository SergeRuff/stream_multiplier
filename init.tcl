
proc _fix_mti_rpc {args} {
    if {[info exists ::VsimHost] && $::VsimHost eq "::1"} {
        set ::VsimHost "127.0.0.1"
    }
    if {[info commands mti_MakeRPCClient] ne "" && [info commands _orig_mti_MakeRPCClient] eq ""} {
        rename mti_MakeRPCClient _orig_mti_MakeRPCClient
        proc mti_MakeRPCClient {args} {
            set new_args {}
            foreach a $args {
                lappend new_args [expr {$a eq "::1" ? "127.0.0.1" : [string map {"::1:" "127.0.0.1:"} $a]}]
            }
            return [uplevel 1 [list _orig_mti_MakeRPCClient {*}$new_args]]
        }
    }
    if {[info commands mti_MakeRPCServer] ne "" && [info commands _orig_mti_MakeRPCServer] eq ""} {
        rename mti_MakeRPCServer _orig_mti_MakeRPCServer
        proc mti_MakeRPCServer {args} {
            set r [uplevel 1 [list _orig_mti_MakeRPCServer {*}$args]]
            if {[lindex $r 1] eq "::1"} { lset r 1 "127.0.0.1" }
            return $r
        }
    }
}
trace add variable ::VsimHost write _fix_mti_rpc
trace add variable ::rpc_port write _fix_mti_rpc
trace add variable ::serverList write _fix_mti_rpc

