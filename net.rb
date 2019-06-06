require 'snapshot'
require 'util'

#  The dev pseudo-file contains network device status information. This gives the number of received and sent packets, the number of errors and
#  collisions and other basic statistics. These are used by the ifconfig(8) program to report device status.  The format is:

# Inter-|   Receive                                                |  Transmit
#  face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#     lo: 2776770   11307    0    0    0     0          0         0  2776770   11307    0    0    0     0       0          0
#   eth0: 1215645    2751    0    0    0     0          0         0  1782404    4324    0    0    0   427       0          0
#   ppp0: 1622270    5552    1    0    0     0          0         0   354130    5669    0    0    0     0       0          0
#   tap0:    7714      81    0    0    0     0          0         0     7714      81    0    0    0     0       0          0

class Net < Snapshot
    def initialize
        super
        interfaces_ipv4 = Dir["/proc/sys/net/ipv4/conf/*"].collect {|x| x=~/.*\/(.+)$/; $1}
        interfaces_ipv6 = Dir["/proc/sys/net/ipv6/conf/*"].collect {|x| x=~/.*\/(.+)$/; $1}
        @interfaces = interfaces_ipv4 + interfaces_ipv6
        @interfaces = @interfaces.uniq
        @interfaces.delete("lo")
    end

    def refresh
        IO.foreach("/proc/net/dev") do |line|
            if line =~ /^(.+):(.+)$/
                interface = $1.strip
                if @interfaces.include? interface
                    interface = interface.to_sym
                    data = $2.split
                    update3(interface, :recv_bytes, data[0])
                    update3(interface, :recv_pkts,  data[1])
                    update3(interface, :sent_bytes, data[8])
                    update3(interface, :sent_pkts,  data[9])
                end
            end
        end

        update_time
    end

    def interface_count
        count
    end

    def each_interface
        #
        # eth10 should be after eth2 
        #
        interfaces = keys.sort do |k1, k2|
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

        interfaces.each do |interface|
            yield interface
        end
    end

    def each_interface_with_index
        index = 0
        each_interface do |interface|
            yield interface, index
            index = index + 1
        end
    end

    def each_interface_with_detail
        each_interface do |interface|
            recv_bytes = recv_bytes(interface)
            recv_pkts  = recv_pkts(interface)
            sent_bytes = sent_bytes(interface)
            sent_pkts  = sent_pkts(interface)

            yield interface, recv_bytes, recv_pkts, sent_bytes, sent_pkts
        end
    end

    def self.define_net_method(name)
        module_eval %{
            def #{name}(interface=nil)
                if interface.nil?
                    result = 0.0
                    count = 0
                    each_interface do |interface|
                        result = result + #{name}(interface)
                        count = count + 1
                    end
                    count == 0 ? 0.0 : result/count
                else
                    get3_changed_per_second_f(interface, "#{name}".to_sym)
                end
            end
        }
    end

    define_net_method :recv_bytes
    define_net_method :recv_pkts
    define_net_method :sent_bytes
    define_net_method :sent_pkts
end
