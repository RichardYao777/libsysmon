require 'snapshot'
require 'util'

#  cpu
#         The number of jiffies (1/100ths of a  second)  that  the
#         system  spent  in user mode, user mode with low priority
#         (nice), system mode, and the  idle  task,  respectively.
#         The  last  value should be 100 times the second entry in
#         the uptime pseudo-file.

#  btime
#         boot time, in seconds since the epoch (January 1, 1970).

#  processes
#         Number of forks since boot.

class Cpu < Snapshot
    def refresh
        IO.foreach("/proc/stat") do |line|
            if line.match(/cpu\s+/)
                data = line.split
                update3(:cpu, :us, data[1])
                update3(:cpu, :ni, data[2])
                update3(:cpu, :sy, data[3])
                update3(:cpu, :id, data[4])
                update3(:cpu, :wa, data[5])
                update3(:cpu, :hi, data[6])
                update3(:cpu, :si, data[7])
            elsif line.match(/cpu\d+/)
                data = line.split
                cpu = data[0].to_sym
                update3(cpu, :us, data[1])
                update3(cpu, :ni, data[2])
                update3(cpu, :sy, data[3])
                update3(cpu, :id, data[4])
                update3(cpu, :wa, data[5])
                update3(cpu, :hi, data[6])
                update3(cpu, :si, data[7])
            elsif line.match(/btime/)
                data = line.split
                set(:btime, data[1])
            elsif line.match(/processes/)
                data = line.split
                update(:processes, data[1])
            elsif line.match(/procs_running/)
                data = line.split
                set(:procs_running, data[1])
            elsif line.match(/procs_blocked/)
                data = line.split
                set(:procs_blocked, data[1])
            end
        end

        update_time
    end

    def cpu_count
        count-1
    end

    def each_cpu(no_summary=false)
        # 
        # cpu10 should be after cpu2
        #
        cpus = keys.sort do |k1, k2|
               s1 = k1.to_s
               s2 = k2.to_s

               if s1.length == s2.length
                      s1 <=> s2
               elsif s1.length > s2.length
                      1
               else
                      -1
               end
        end

        cpus.each do |cpu|
            next if no_summary and cpu == :cpu
            yield cpu
        end
    end

    def each_cpu_with_index(no_summary=false)
        index = 0
        each_cpu(no_summary) do |cpu|
            yield cpu, index
            index = index + 1
        end
    end

    def each_cpu_with_detail(no_summary=false)
        each_cpu(no_summary) do |cpu|
            us = us_incr(cpu)
            ni = ni_incr(cpu)
            sy = sy_incr(cpu)
            id = id_incr(cpu)
            wa = wa_incr(cpu)
            hi = hi_incr(cpu)
            si = si_incr(cpu)
            yield cpu, us, ni, sy, id, wa, hi, si, us+ni+sy+id+wa+hi+si
        end
    end

    def self.define_cpu_incr(type)
        module_eval %{
            def #{type}_incr(cpu=:cpu)
                get3_changed_i(cpu, "#{type}".to_sym)
            end
        }
    end

    define_cpu_incr :us
    define_cpu_incr :ni
    define_cpu_incr :sy
    define_cpu_incr :id
    define_cpu_incr :wa
    define_cpu_incr :hi
    define_cpu_incr :si

    def cpu_incr(cpu=:cpu)
        us_incr(cpu)+
        ni_incr(cpu)+
        sy_incr(cpu)+
        id_incr(cpu)+
        wa_incr(cpu)+
        hi_incr(cpu)+
        si_incr(cpu)
    end

    def self.define_cpu_usage(type)
        module_eval %{
            def #{type}_usage(cpu=:cpu)
                cpu_incr = cpu_incr(cpu)
                cpu_incr == 0 ? 0.0 : #{type}_incr(cpu)/cpu_incr.to_f
            end
        }
    end

    define_cpu_usage :us
    define_cpu_usage :ni
    define_cpu_usage :sy
    define_cpu_usage :id
    define_cpu_usage :wa
    define_cpu_usage :hi
    define_cpu_usage :si

    def uptime
        left = Time.now.to_i-btime
        day = left/60/60/24
        left = left-day*60*60*24
        hour = left/60/60
        left = left-hour*60*60
        min = left/60
        sec = left-min*60

        [day, hour, min, sec]
    end

    def uptime_string
        day, hour, min, sec = uptime

        up = ""
        if day == 1
            up << "#{day} day,"
        elsif day > 1
            up << "#{day} days,"
        end
        up << sprintf("%02u:%02u:%02u", hour, min, sec)
        up
    end

    def btime
        get_i(:btime)
    end

    def processes
        get_changed_per_second_i(:processes)
    end

    def procs_running
        get_i(:procs_running)
    end

    def procs_blocked
        get_i(:procs_blocked)
    end
end
