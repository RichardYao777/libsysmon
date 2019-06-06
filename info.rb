require 'singleton'
require 'cpu'
require 'loadavg'
require 'mem'
require 'vm'
require 'net'
require 'procs'
require 'history'

class Info
    include Singleton

    attr_reader :cpu, :loadavg, :mem, :vm, :net, :procs
    attr_reader :his_cpu, :his_loadavg_1, :his_loadavg_5, :his_loadavg_15
    attr_reader :his_mem, :his_swap
    attr_reader :his_disk_in, :his_disk_out, :his_swap_in, :his_swap_out
    attr_reader :his_net_recv, :his_net_sent

    def initialize
        @cpu        = Cpu.new
        @loadavg    = Loadavg.new
        @mem        = Mem.new
        @vm         = Vm.new
        @net        = Net.new
        @procs      = Procs.new

        @cpu.refresh
        @loadavg.refresh
        @mem.refresh
        @vm.refresh
        @net.refresh
        @procs.refresh

        @his_loadavg_1  = History.new(10)
        @his_loadavg_5  = History.new(10)
        @his_loadavg_15 = History.new(10)
        @his_mem        = History.new
        @his_swap       = History.new
        @his_disk_in    = History.new
        @his_disk_out   = History.new
        @his_swap_in    = History.new
        @his_swap_out   = History.new

        @his_cpu = {}
        @cpu.each_cpu do |cpu|
            @his_cpu[cpu] = History.new(1.0)
        end

        @his_net_recv   = {:all => History.new}
        @his_net_sent   = {:all => History.new}
        @net.each_interface do |interface|
            @his_net_recv[interface] = History.new
            @his_net_sent[interface] = History.new
        end

        # First time refresh
        refresh(true)
    end

    def init
    end

    def refresh_cpu(first=false)
        # For first time refresh, interval is too short, ignore it.
        if first
            @cpu.each_cpu do |cpu|
                @his_cpu[cpu] << 0.0
            end
        else
            @cpu.refresh

            @cpu.each_cpu do |cpu|
                @his_cpu[cpu] << 1.0-@cpu.id_usage(cpu)
            end
        end
    end

    def refresh_loadavg
        @loadavg.refresh

        @his_loadavg_1  << @loadavg.loadavg_1
        @his_loadavg_5  << @loadavg.loadavg_5
        @his_loadavg_15 << @loadavg.loadavg_15
    end

    def refresh_mem
        @mem.refresh

        @his_mem.base = @mem.mem_total
        @his_mem << @mem.mem_real_used

        @his_swap.base = @mem.swap_total
        @his_swap << @mem.swap_used
    end

    def refresh_vm
        @vm.refresh

        @his_disk_in  << @vm.bi
        @his_disk_out << @vm.bo
        @his_swap_in  << @vm.si
        @his_swap_out << @vm.so
    end

    def refresh_net
        @net.refresh

        @his_net_recv[:all] << @net.recv_bytes
        @his_net_sent[:all] << @net.sent_bytes
        @net.each_interface do |interface|
            @his_net_recv[interface] << @net.recv_bytes(interface)
            @his_net_sent[interface] << @net.sent_bytes(interface)
        end
    end

    def refresh_procs
        @procs.refresh
    end

    def refresh(first=false)
        refresh_cpu(first)
        refresh_loadavg
        refresh_mem
        refresh_vm
        refresh_net
        refresh_procs
    end
end
