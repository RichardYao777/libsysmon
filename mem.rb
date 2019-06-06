require 'snapshot'

class Mem < Snapshot
    def refresh
        IO.foreach("/proc/meminfo") do |line|
            if line =~ /(.+):\s*?(\d+)/
                set($1.downcase.to_sym, $2)
            end
        end
    end

    def self.define_mem_method(method, name)
        module_eval %{
            def #{method}
                get_i("#{name}".to_sym)
            end
        }
    end

    define_mem_method :mem_total,   :memtotal
    define_mem_method :mem_free,    :memfree
    define_mem_method :swap_total,  :swaptotal
    define_mem_method :swap_free,   :swapfree
    define_mem_method :buffers,     :buffers
    define_mem_method :cached,      :cached

    def mem_used
        mem_total-mem_free
    end

    def mem_real_used
        mem_used-buffers-cached
    end

    def swap_used
        swap_total-swap_free
    end
end
