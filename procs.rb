require 'snapshot'

# pid        process id
# ppid       parent process id
# name       process name
# state      "RSDZTW" running/sleeping/disk sleep/zombie/traced/paging
# priority   kernel scheduling priority
# nice       standard unix nice level of process
# nlwp       number of threads, or 0 if no clue
# vm_size    Virtual memory (number of pages)
# vm_rss     Resident Set Size (number of pages)
# vm_share   Shared (number of pages)
# utime      user-mode CPU time accumulated by process
# stime      kernel-mode CPU time accumulated by process

class Procs < Snapshot
    def refresh
        procs = Dir["/proc/*"].collect {|x| x=~/.*\/(.+)$/; $1}.grep(/\d+/).collect {|x| x.to_i}

        # Delete the dead process(es)
        delete_except(procs)

        procs.each do |pid|
            begin
                name = nil
                data1 = nil
                data2 = nil
                uid = 0
                gid = 0
                peak = 0
                heap = 0
                line1 = File.new("/proc/#{pid}/stat").readline
                if line1 =~ /.+ \((.+)\) (.+)/
                    name = $1 
                    data1 = $2.split
                    line2 = File.new("/proc/#{pid}/statm").readline
                    data2 = line2.split
                    IO.foreach("/proc/#{pid}/status") do |line3|
                        if line3 =~ /Uid:[ \t]+(\d+)[ \t]+.+/
                            uid = $1
                        elsif line3 =~ /Gid:[ \t]+(\d+)[ \t]+.+/
                            gid = $1
                        elsif line3 =~ /VmPeak:[ \t]+(\d+)[ \t]+kB/
                            peak = $1
                        elsif line3 =~ /VmData:[ \t]+(\d+)[ \t]+kB/
                            heap = $1
                        end
                    end
                end

                unless name.nil? or data1.nil? or data2.nil?
                    set3(pid, :ppid,     data1[1])
                    set3(pid, :uid,      uid)
                    set3(pid, :gid,      gid)
                    set3(pid, :state,    data1[0])
                    set3(pid, :vm_size,  data2[0])
                    set3(pid, :vm_rss,   data2[1])
                    set3(pid, :vm_share, data2[2])
                    set3(pid, :vm_peak,  peak)
                    set3(pid, :vm_data,  heap)
                    set3(pid, :priority, data1[15])
                    set3(pid, :nice,     data1[16])
                    set3(pid, :nlwp,     data1[17])
                    set3(pid, :name,     name)

                    update3(pid, :utime, data1[11])
                    update3(pid, :stime, data1[12])
                end
            # Process maybe already dead when we try to read the file
            rescue
            end
        end
    end

    def nproc
        count
    end

    def name(pid)
        get3(pid, :name)
    end

    def state(pid)
        get3(pid, :state)
    end

    def pid(pid)
        pid
    end

    def ppid(pid)
        get3_i(pid, :ppid)
    end

    def uid(pid)
        get3_i(pid, :uid)
    end

    def gid(pid)
        get3_i(pid, :gid)
    end

    def cpu(pid)
        utime = get3_changed_i(pid, :utime)
        stime = get3_changed_i(pid, :stime)
        utime+stime
    end

    def state(pid)
        get3(pid, :state)
    end

    def vm_rss(pid)
        get3_i(pid, :vm_rss)
    end

    def vm_size(pid)
        get3_i(pid, :vm_size)
    end

    def vm_share(pid)
        get3_i(pid, :vm_share)
    end

    def vm_peak(pid)
        get3_i(pid, :vm_peak)
    end

    def vm_data(pid)
        get3_i(pid, :vm_data)
    end

    def priority(pid)
        get3_i(pid, :priority)
    end

    def nice(pid)
        get3_i(pid, :nice)
    end

    def nlwp(pid)
        get3_i(pid, :nlwp)
    end

    def name(pid)
        get3(pid, :name)
    end

    def top_proc(sort_by, is_sort_asc, cur_line, max, detail)
        procs = []

        each_type do |pid|
            procs << [pid, send(sort_by, pid)]
        end

        procs.sort! do |x, y|
            is_sort_asc ? x.last<=>y.last : y.last<=>x.last
        end

        window_index = 0
        procs.each_with_index do |p, total_index|
            next if cur_line>=max and total_index<=cur_line-max
            break if window_index >= max

            pid = p.first

            unless detail
                yield total_index, pid, name(pid), p.last
            else
                yield window_index, total_index,
                    pid, ppid(pid), uid(pid), gid(pid), state(pid), cpu(pid),
                    vm_size(pid), vm_rss(pid), vm_share(pid),
                    vm_peak(pid), vm_data(pid),
                    priority(pid), nice(pid), nlwp(pid), name(pid)
            end

            window_index = window_index + 1
        end
    end
end
