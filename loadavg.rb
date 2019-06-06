require 'snapshot'

#  The load average numbers give the number of jobs in the run queue (state R) or waiting for disk I/O (state D) averaged over  1,  5,  and  15
#  minutes.  They are the same as the load average numbers given by uptime(1) and other programs.

class Loadavg < Snapshot
    def refresh
        data = File.new("/proc/loadavg").readline.split
        set(:loadavg_1, data[0])
        set(:loadavg_5, data[1])
        set(:loadavg_15, data[2])
    end

    def loadavg_1
        get_f(:loadavg_1)
    end

    def loadavg_5
        get_f(:loadavg_5)
    end

    def loadavg_15
        get_f(:loadavg_15)
    end
end
