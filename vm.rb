require 'snapshot'

#   IO
#       bi: Blocks received from a block device (blocks/s).
#       bo: Blocks sent to a block device (blocks/s).

#   Swap
#       si: Amount of memory swapped in from disk (/s).
#       so: Amount of memory swapped to disk (/s).


class Vm < Snapshot
    def refresh
        IO.foreach("/proc/vmstat") do |line|
            if line =~ /(.+)\s+?(\d+)$/
                update($1.downcase.to_sym, $2)
            end
        end

        update_time
    end

    def bi
        get_changed_per_second_i(:pgpgin)
    end

    def bo
        get_changed_per_second_i(:pgpgout)
    end

    def si
        get_changed_per_second_i(:pswpin)
    end

    def so
        get_changed_per_second_i(:pswpout)
    end
end
