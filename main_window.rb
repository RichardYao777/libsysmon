require 'singleton'
require 'util'
require 'console'
require 'info'
require 'state'
require 'user'

class MainWindowBase
    @@pagesize = 4096
    @@fullscreen_col = 4
    @@fullscreen_row = 3
    @@file_color = {}
    @@file_color[:file]              = Ncurses::COLOR_WHITE
    @@file_color[:directory]         = Ncurses::COLOR_BLUE
    @@file_color[:link]              = Ncurses::COLOR_YELLOW
    @@file_color[:characterSpecial]  = Ncurses::COLOR_CYAN 
    @@file_color[:blockSpecial]      = Ncurses::COLOR_MAGENTA
    @@file_color[:fifo]              = Ncurses::COLOR_GREEN
    @@file_color[:socket]            = Ncurses::COLOR_GREEN
    @@file_color[:unknow]            = Ncurses::COLOR_RED

    def refresh
        h, w = Console::getmaxyx
        Console::clear
        State.instance.current_state.refresh(w, h-1)
        State.instance.current_state.draw_bottom(w, h)
        draw_debug
        Console::refresh
    end

    def refresh_bottom
        h, w = Console::getmaxyx
        Console::draw_string(0, h-1, w, " "*w)
        State.instance.current_state.draw_bottom(w, h)
        draw_debug
        Console::refresh
    end

    def draw_open_file(w, h, pid, open_file, cur_line)
        # Draw axis
        Console::draw_axis(0, 0, w, h, Ncurses::COLOR_BLUE)

        # Draw first line
        name = Info.instance.procs.name(pid)
        if name.nil?
            Console::draw_string(1, 0, w-1, "The process of pid=#{pid} has been already dead", false, Ncurses::COLOR_RED)
        else
            Console::draw_string(1, 0, w-1, "Open files of pid=#{pid} name=<#{name}> total=#{open_file.count}:", false, Ncurses::COLOR_RED)

            # Draw open files
            total_index = -1
            window_index = 0
            max = h-2
            cur_line_index = nil
            cur_line_string = nil
            cur_line_fd = nil
            cur_line_fname = nil

            open_file.each do |fd, fname, ftype|
                #debug "cur=#{cur_line} max=#{max} win=#{window_index} total=#{total_index} h=#{h}"
                total_index = total_index + 1

                next if cur_line>=max and total_index<=cur_line-max
                break if window_index>=max

                color = @@file_color[ftype]
                color = Ncurses::COLOR_RED if color.nil?
                s = "#{fd}-> #{fname}"

                Console::draw_string(1, window_index+1, w-1, s, false, color)
                if total_index == cur_line
                    cur_line_index = window_index
                    cur_line_string = s
                    cur_line_fd = fd
                    cur_line_fname = fname
                end

                window_index = window_index + 1
            end

            # Draw current line
            unless cur_line_index.nil? or cur_line_string.nil?
                Console::draw_string(1, cur_line_index+1, w-1, cur_line_string, false, Ncurses::COLOR_WHITE, true)
                info = "#{cur_line+1}/#{open_file.count}"
                file_status = "#{FileUtil.file_status(cur_line_fname)}"
                info = "#{info} #{file_status}" unless file_status.empty?
                Console.draw_string(1, h-1, w-1, info, false, Ncurses::COLOR_WHITE, true)
            end
        end
    end

    def draw_debug
        # Default is doing nothing
    end

    def debug(s)
        # Overwrite the draw_debug method
        eval %{
            def draw_debug
                h, w = Console::getmaxyx
                Console::draw_string(0, h-1, w, " "*w)
                Console::draw_string(0, h-1, w, "#{s}", false, Ncurses::COLOR_RED)
            end
        }
    end

    protected

    def position(total_w, total_h, total_col, total_row,
                 index_x, index_y, col, row, orignal_x=0, orignal_y=0)

        col_len = total_w/total_col
        row_len = total_h/total_row

        x = orignal_x + col_len * index_x
        y = orignal_y + row_len * index_y

        # Last col?
        if index_x+col != total_col
            w = col_len * col
        # Last col!
        else
            w = col_len*(col-1) + total_w-col_len*(total_col-1) 
        end

        # Last row?
        if index_y+row != total_row
            h = row_len * row
        # Last row!
        else
            h = row_len*(row-1) + total_h-row_len*(total_row-1) 
        end

        return x, y, w, h
    end

    ###########################################################################
    #
    def draw(x, y, w, h,
             max, base, hotkey,
             histogram, strings,
             check_level, check_high=true, warn=0.5, alarm=0.8)
        # Draw axis
        Console::draw_axis(x, y, w, h, Ncurses::COLOR_BLUE)

        # Draw histogram
        histogram.look_back_with_index(w-1) do |data, index|
            # Audit
            per = base.to_f==0.0 ? 0.0 : data/base.to_f
            color = Ncurses::COLOR_GREEN
            if check_level
                if check_high
                    color = Ncurses::COLOR_YELLOW if per > warn
                    color = Ncurses::COLOR_RED if per > alarm
                else
                    color = Ncurses::COLOR_YELLOW if per < warn
                    color = Ncurses::COLOR_RED if per < alarm
                end
            end

            # Length
            per = max.to_f==0.0 ? 0 : data/(max*1.1)
            len = (per*(h-1)).to_i

            hx = (x+w-1) - (histogram.size-1-index)
            if len <= 0
                Console::draw_color_char(hx, y+h-1-1, ?_, color)
            else
                Console::reverse_on
                Console::draw_v_line(hx, y+h-1-len, len, 32, color)
                Console::reverse_off
            end
        end

        # Draw strings
        Console::draw_strings(x+1, y, w-1, h-1, strings, false, Ncurses::COLOR_WHITE)

        # Draw hotkey
        Console::draw_color_char(x+w-1, y+h-1, hotkey, Ncurses::COLOR_RED) if hotkey != 0 
    end

    def draw_strings(x, y, w, h, hotkey, strings)
        # Draw axis
        Console::draw_axis(x, y, w, h, Ncurses::COLOR_BLUE)

        # Draw strings
        Console::draw_strings(x+1, y, w-1, h-1, strings, false, Ncurses::COLOR_WHITE)

        # Draw hotkey
        Console::draw_color_char(x+w-1, y+h-1, hotkey, Ncurses::COLOR_RED) if hotkey != 0
    end
    #
    ###########################################################################

    ###########################################################################
    #
    def self.to_same_s(arg)
        if arg.is_a?(NilClass)
            'nil'
        elsif arg.is_a?(Symbol)
            ":#{arg}"
        else
            arg
        end
    end

    def self.define_draw(mode, type, hotkey, total_col, total_row, index_x, index_y, col, row, arg=nil)
        module_eval %{
            def draw_#{mode}_#{type}(total_w, total_h, argument=#{to_same_s(arg)})
                x, y, w, h = position(total_w, total_h,
                                      #{total_col}, #{total_row},
                                      #{index_x}, #{index_y},
                                      #{col}, #{row})
                if argument.nil?
                    draw_#{type}(x, y, w, h, #{hotkey})
                else    
                    if argument.is_a?(Array)
                        draw_#{type}(x, y, w, h, #{hotkey}, *argument)
                    else
                        draw_#{type}(x, y, w, h, #{hotkey}, argument)
                    end
                end
            end
        }
    end

    def self.define_draw_fullscreen(type, hotkey, index_x, index_y, arg=nil)
        define_draw :fullscreen, type, hotkey, @@fullscreen_col, @@fullscreen_row, index_x, index_y, 1, 1, arg
    end

    def self.define_draw_subwindow(type, col, row, index_x, index_y, arg=nil)
        define_draw :subwindow, type, 0, col, row, index_x, index_y, 1, 1, arg
    end
    #
    ###########################################################################

    ###########################################################################
    #
    def draw_cpu(x, y, w, h, hotkey, detail)
        unless detail
            draw_cpu_of(:cpu, x, y, w, h, hotkey)
        else
            min_col = 4
            no_summary = true
            cpu_count = Info.instance.cpu.cpu_count

            total_col = [cpu_count, min_col].min
            total_row = (cpu_count-1)/min_col+1
            Info.instance.cpu.each_cpu_with_index(no_summary) do |cpu, index|
                x0, y0, w0, h0 = position(w, h, total_col, total_row,
                                          index%total_col, index/total_col, 1, 1)
                draw_cpu_of(cpu, x0, y0, w0, h0, hotkey)
            end

            # Draw empty axis
            if cpu_count > min_col
                cpu_count.upto(min_col*total_row-1) do |index|
                    x0, y0, w0, h0 = position(w, h, total_col, total_row,
                                              index%total_col, index/total_col, 1, 1)
                    Console::draw_axis(x0, y0, w0, h0, Ncurses::COLOR_BLUE)
                end
            end
        end
    end

    def draw_cpu_of(cpu, x, y, w, h, hotkey)
        dataw = (w-1)*2
        base = Info.instance.his_cpu[cpu].base_of(dataw)
        draw(x, y, w, h,
             base,
             base,
             hotkey,
             Info.instance.his_cpu[cpu],
             strings_of_cpu(cpu, dataw),
             true)
    end

    def strings_of_cpu(cpu_id, dataw)
        his_cpu = Info.instance.his_cpu[cpu_id]
        cpu     = Info.instance.cpu
        procs   = Info.instance.procs
        return [] if his_cpu.empty?

        strings = []
        # Line 1
        if cpu_id == :cpu
            s = sprintf("%d CPU: %.2f%% %.2f%%~%.2f%%",
                        cpu.cpu_count,
                        his_cpu.last*100,
                        his_cpu.min_of(dataw)*100,
                        his_cpu.max_of(dataw)*100)
        else
            s = sprintf("%s: %.2f%% %.2f%%~%.2f%%",
                        cpu_id,
                        his_cpu.last*100,
                        his_cpu.min_of(dataw)*100,
                        his_cpu.max_of(dataw)*100)
        end
        strings << s

        # Line 2
        s = sprintf("us=%.2f%% sy=%.2f%%",
                    cpu.us_usage(cpu_id)*100,
                    cpu.sy_usage(cpu_id)*100)
        strings << s

        # Line 3
        s = sprintf("id=%.2f%% wa=%.2f%%",
                    cpu.id_usage(cpu_id)*100,
                    cpu.wa_usage(cpu_id)*100)
        strings << s

        # Line 4
        s = sprintf("ni=%.2f%% hi=%.2f%% si=%.2f%%",
                    cpu.ni_usage(cpu_id)*100,
                    cpu.hi_usage(cpu_id)*100,
                    cpu.si_usage(cpu_id)*100)
        strings << s

        if cpu_id == :cpu
            # Line 5
            s = sprintf("procs total=%u fork=%u/s",
                        procs.nproc,
                        cpu.processes)
            strings << s

            # Line 6
            s = sprintf("procs running=%u blocked=%u",
                        cpu.procs_running,
                        cpu.procs_blocked)
            strings << s


            # Line 7
            s = sprintf("uptime %s", cpu.uptime_string)
            strings << s
        end

        strings
    end
    #
    ###########################################################################
    
    ###########################################################################
    #
    def self.define_draw_loadavg(type)
        module_eval %{
            def draw_loadavg_#{type}(x, y, w, h, hotkey)
                dataw = (w-1)*2
                max = [Info.instance.his_loadavg_1.max_of(dataw),
                       Info.instance.his_loadavg_5.max_of(dataw),
                       Info.instance.his_loadavg_15.max_of(dataw)].max
                base = Info.instance.his_loadavg_#{type}.base_of(dataw)
                draw(x, y, w, h,
                     max,
                     base,
                     hotkey,
                     Info.instance.his_loadavg_#{type},
                     strings_of_loadavg_#{type}(dataw),
                     true)
            end
        }
    end

    def self.define_loadavg_string_of(type)
        module_eval %{
            def strings_of_loadavg_#{type}(dataw)
                his_loadavg = Info.instance.his_loadavg_#{type}
                return [] if his_loadavg.empty?

                strings = []
                # Line 1
                s = sprintf("Loadavg #{type}m: %.2f %.2f~%.2f",
                            his_loadavg.last,
                            his_loadavg.min_of(dataw),
                            his_loadavg.max_of(dataw));
                strings << s
            end
        }
    end
    #
    ###########################################################################

    ###########################################################################
    #
    def self.define_draw_top(type)
        module_eval %{
            def draw_top_#{type}(x, y, w, h, hotkey, sort_by=nil, is_sort_asc=false, cur_line=0)
                if sort_by.nil?
                    draw_top_#{type}_summary(x, y, w, h, hotkey)
                else
                    draw_top_#{type}_detail(x, y, w, h, hotkey, sort_by, is_sort_asc, cur_line)
                end
            end
        }
    end

    def self.define_draw_top_proc_detail(type)
        module_eval %{
            def draw_top_#{type}_detail(x, y, w, h, hotkey, sort_by, is_sort_asc, cur_line)
                strings = []
                specials = []
                cur_line_pid = nil
                cur_line_index = nil
                cur_line_string = nil
                cur_line_uid = nil
                cur_line_gid = nil
                s = sprintf("%5.5s %5.5s %5.5s %5.5s S %6.6s %5.5s %6.6s %6.6s %6.6s %6.6s %6.6s PRIO NICE THR CMD",
                            "PID",
                            "PPID",
                            "UID",
                            "GID",
                            "%CPU",
                            "%MEM",
                            "VM",
                            "MEM",
                            "SHARE",
                            "PEAK",
                            "HEAP")
                strings << s
                strings << "" 

                cpu_count = Info.instance.cpu.cpu_count
                cpu_incr = Info.instance.cpu.cpu_incr.to_f/cpu_count
                mem_total = Info.instance.mem.mem_total.to_f
                Info.instance.procs.top_proc(
                    sort_by, is_sort_asc, cur_line, h-2-1, true) do |index, total_index,
                                                                     pid, ppid, uid, gid, state, cpu,
                                                                     vm_size, vm_rss, vm_share,
                                                                     vm_peak, vm_data,
                                                                     priority, nice, nlwp, name|
                    cpu_usage = cpu_incr.zero? ? 0 : cpu/cpu_incr*100
                    s = sprintf("%5d %5d %5d %5d %s %5.1f%% %4.1f%% %6s %6s %6s %6s %6s %4d %4d %3d %s",
                                 pid,
                                 ppid,
                                 uid,
                                 gid,
                                 state,
                                 cpu_usage,
                                 vm_rss*(@@pagesize/1024)/mem_total*100,
                                 (vm_size*@@pagesize).to_unit_string,
                                 (vm_rss*@@pagesize).to_unit_string,
                                 (vm_share*@@pagesize).to_unit_string,
                                 (vm_peak*1024).to_unit_string,
                                 (vm_data*1024).to_unit_string,
                                 priority,
                                 nice,
                                 nlwp,
                                 name)
                    state = state.to_sym
                    if state != :S
                        strings << ""
                        specials << [index, state, s]
                    else
                        strings << s
                    end

                    if total_index == cur_line
                        cur_line_pid = pid
                        cur_line_index = index
                        cur_line_string = s
                        cur_line_uid = uid
                        cur_line_gid = gid
                        State.instance.current_state.cur_pid = pid
                    end
                end

                # Draw processes
                draw_strings(x, y, w, h, hotkey, strings)

                # Draw sort by
                case sort_by
                when :pid
                    Console::draw_string(3, 0, 3, "PID", false, Ncurses::COLOR_GREEN)
                when :ppid
                    Console::draw_string(8, 0, 4, "PPID", false, Ncurses::COLOR_GREEN)
                when :uid
                    Console::draw_string(15, 0, 3, "UID", false, Ncurses::COLOR_GREEN)
                when :gid
                    Console::draw_string(21, 0, 3, "GID", false, Ncurses::COLOR_GREEN)
                when :state
                    Console::draw_string(25, 0, 1, "S", false, Ncurses::COLOR_GREEN)
                when :cpu
                    Console::draw_string(29, 0, 4, "%CPU", false, Ncurses::COLOR_GREEN)
                when :vm_rss
                    Console::draw_string(35, 0, 4, "%MEM", false, Ncurses::COLOR_GREEN)
                    Console::draw_string(50, 0, 3, "MEM", false, Ncurses::COLOR_GREEN)
                when :vm_size
                    Console::draw_string(44, 0, 2, "VM", false, Ncurses::COLOR_GREEN)
                when :vm_share
                    Console::draw_string(55, 0, 5, "SHARE", false, Ncurses::COLOR_GREEN)
                when :vm_peak
                    Console::draw_string(63, 0, 4, "PEAK", false, Ncurses::COLOR_GREEN)
                when :vm_data
                    Console::draw_string(70, 0, 4, "HEAP", false, Ncurses::COLOR_GREEN)
                when :priority
                    Console::draw_string(75, 0, 4, "PRIO", false, Ncurses::COLOR_GREEN)
                when :nice
                    Console::draw_string(80, 0, 4, "NICE", false, Ncurses::COLOR_GREEN)
                when :nlwp
                    Console::draw_string(85, 0, 3, "THR", false, Ncurses::COLOR_GREEN)
                when :name
                    Console::draw_string(89, 0, 3, "CMD", false, Ncurses::COLOR_GREEN)
                end

                # Draw special processes
                specials.each do |index, state, s|
                    color = state==:R ? Ncurses::COLOR_CYAN : Ncurses::COLOR_MAGENTA
                    Console.draw_string(x+1, y+2+index, w-1, s, false, color)
                end

                # Draw the current line
                unless cur_line_pid.nil? or
                       cur_line_index.nil? or
                       cur_line_string.nil? or
                       cur_line_uid.nil? or
                       cur_line_gid.nil?
                    Console.draw_string(x+1, y+2+cur_line_index, w-1, cur_line_string,
                        false, Ncurses::COLOR_WHITE, true)

                    position = "\#{(cur_line+1).to_s}/\#{Info.instance.procs.count.to_s}"
                    user = User.instance.user cur_line_uid
                    group = User.instance.group cur_line_gid
                    cwd = ProcUtil.cwd cur_line_pid
                    exe = ProcUtil.exe cur_line_pid
                    cmd = ProcUtil.cmdline cur_line_pid
                    cur_line_info = "\#{position} \#{user}:\#{group}"
                    cur_line_info = "\#{cur_line_info} exe=\#{exe}" unless exe.nil?
                    cur_line_info = "\#{cur_line_info} cmd=\\"\#{cmd}\\"" unless cmd.nil?
                    cur_line_info = "\#{cur_line_info} pwd=\#{cwd}" unless cwd.nil?
                    Console.draw_string(x+1, h-1, w-1, cur_line_info,
                        false, Ncurses::COLOR_WHITE, true)
                end
            end
        }
    end

    def draw_top_cpu_summary(x, y, w, h, hotkey)
        strings = []
        s = sprintf("%5.5s %5.5s CMD", "PID", "%CPU")
        strings << s
        strings << "" 

        cpu_count = Info.instance.cpu.cpu_count
        cpu_incr = Info.instance.cpu.cpu_incr.to_f/cpu_count
        Info.instance.procs.top_proc(:cpu, false, 0, h-2-1, false) do |index, pid, name, cpu|
            cpu_usage = cpu_incr.zero? ? 0 : cpu/cpu_incr*100
            s = sprintf("%5d %4.1f%% %s", pid, cpu_usage, name)
            strings << s
        end
        draw_strings(x, y, w, h, hotkey, strings)
    end

    def draw_top_mem_summary(x, y, w, h, hotkey)
        strings = []
        s = sprintf("%5.5s %5.5s %6.6s CMD", "PID", "%MEM", "MEM")
        strings << s
        strings << "" 

        mem_total = Info.instance.mem.mem_total.to_f
        Info.instance.procs.top_proc(:vm_rss, false, 0, h-2-1, false) do |index, pid, name, vm_rss|
            s = sprintf("%5d %4.1f%% %6s %s",
                        pid,
                        vm_rss*(@@pagesize/1024)/mem_total*100,
                        (vm_rss*@@pagesize).to_unit_string,
                        name)
            strings << s
        end
        draw_strings(x, y, w, h, hotkey, strings)
    end
    #
    ###########################################################################

    ###########################################################################
    #
    def self.define_draw_mem(type)
        module_eval %{
            def draw_#{type}(x, y, w, h, hotkey)
                dataw = (w-1)*2
                base = Info.instance.his_#{type}.base_of(dataw)
                draw(x, y, w, h,
                     base,
                     base,
                     hotkey,
                     Info.instance.his_#{type},
                     strings_of_#{type}(dataw),
                     true)
            end
        }
    end

    def self.define_mem_string_of(type)
        module_eval %{
            def strings_of_#{type}(dataw)
                his_mem = Info.instance.his_#{type}
                mem     = Info.instance.mem
                return [] if his_mem.empty?

                strings = []
                # Line 1
                base = his_mem.base_of(dataw).to_f
                s = sprintf("#{type.to_s.capitalize}: %.2f%% %.2f%%~%.2f%%",
                            his_mem.last/base*100,
                            his_mem.min_of(dataw)/base*100,
                            his_mem.max_of(dataw)/base*100)
                strings << s

                # Line 2
                s = sprintf("total=%s free=%s",
                            (mem.#{type}_total*1024).to_unit_string,
                            (mem.#{type}_free*1024).to_unit_string)
                strings << s


                if "#{type}".to_sym == :mem
                    # Line 3
                    s = sprintf("used=%s real_used=%s",
                                (mem.#{type}_used*1024).to_unit_string,
                                (mem.mem_real_used()*1024).to_unit_string)
                    strings << s
                    # Line 4
                    s = sprintf("buffers=%s cached=%s",
                                (mem.buffers()*1024).to_unit_string,
                                (mem.cached()*1024).to_unit_string)
                    strings << s
                else
                    # Line 3
                    s = sprintf("used=%s",
                                (mem.#{type}_used*1024).to_unit_string)
                    strings << s
                end

                strings
            end
        }
    end
    #
    ###########################################################################

    ###########################################################################
    #
    def self.define_draw_net(type)
        module_eval %{
            def draw_net_#{type}(x, y, w, h, hotkey, detail)
                unless detail
                    draw_net_#{type}_of(:all, x, y, w, h, hotkey)
                else
                    interface_count = Info.instance.net.interface_count

                    total_col = 1 
                    total_row = interface_count 
                    Info.instance.net.each_interface_with_index do |interface, index|
                        x0, y0, w0, h0 = position(w, h, total_col, total_row,
                                                  index%total_col, index/total_col,
                                                  1, 1,
                                                  x, y)
                        draw_net_#{type}_of(interface, x0, y0, w0, h0, hotkey)
                    end
                end
            end
        }
    end

    def self.define_draw_net_of(type)
        module_eval %{
            def draw_net_#{type}_of(interface, x, y, w, h, hotkey)
                dataw = (w-1)*2
                max = [Info.instance.his_net_recv[interface].max_of(dataw),
                       Info.instance.his_net_sent[interface].max_of(dataw)].max
                draw(x, y, w, h,
                     max,
                     max,
                     hotkey,
                     Info.instance.his_net_#{type}[interface],
                     strings_of_net_#{type}(interface, dataw),
                     false)
            end
        }
    end

    def self.define_net_string_of(type)
        module_eval %{
            def strings_of_net_#{type}(interface, dataw)
                his_net = Info.instance.his_net_#{type}[interface]
                net     = Info.instance.net
                return [] if his_net.empty?

                strings = []
                # Line 1
                if interface == :all
                    s = sprintf("Net #{type.to_s.capitalize}: %s/s %s/s~%s/s",
                             his_net.last.to_unit_string,
                             his_net.min_of(dataw).to_unit_string,
                             his_net.max_of(dataw).to_unit_string)
                    strings << s
                else
                    s = sprintf("\#{interface} #{type}: %s/s %s/s~%s/s",
                             his_net.last.to_unit_string,
                             his_net.min_of(dataw).to_unit_string,
                             his_net.max_of(dataw).to_unit_string)
                    strings << s
                end

                # Line 2
                s = sprintf("%u packets/s", net.#{type}_pkts(interface))
                strings << s
            end
        }
    end
    #
    ###########################################################################

    ###########################################################################
    #
    def self.define_draw_vm(type, direction, title=nil)
        module_eval %{
            def draw_#{type}_#{direction}(x, y, w, h, hotkey)
                dataw = (w-1)*2
                max = [Info.instance.his_#{type}_in.max_of(dataw),
                       Info.instance.his_#{type}_out.max_of(dataw)].max
                draw(x, y, w, h,
                     max,
                     max,
                     hotkey,
                     Info.instance.his_#{type}_#{direction},
                     strings_of_#{type}_#{direction}(dataw),
                     false)
            end
        }
    end

    def self.define_vm_string_of(type, direction, title)
        module_eval %{
            def strings_of_#{type}_#{direction}(dataw)
                his_vm = Info.instance.his_#{type}_#{direction}
                return [] if his_vm.empty?

                strings = []
                # Line 1
                s = sprintf("#{title}: %s/s %s/s~%s/s",
                            (his_vm.last*1024).to_unit_string,
                            (his_vm.min_of(dataw)*1024).to_unit_string,
                            (his_vm.max_of(dataw)*1024).to_unit_string)
                strings << s
            end
        }
    end
    #
    ###########################################################################
end

class MainWindow < MainWindowBase
    include Singleton

    private

    ###########################################################################
    #
    define_draw_fullscreen :cpu,       ?1, 0, 0, false
    define_draw_fullscreen :loadavg_1, ?2, 1, 0
    define_draw_fullscreen :top_cpu,   ?3, 2, 0, nil 
    define_draw_fullscreen :top_mem,   ?4, 3, 0, nil
    define_draw_fullscreen :mem,       ?5, 0, 1
    define_draw_fullscreen :swap,      ?5, 1, 1
    define_draw_fullscreen :net_recv,  ?6, 2, 1, false
    define_draw_fullscreen :net_sent,  ?6, 3, 1, false
    define_draw_fullscreen :disk_in,   ?7, 0, 2
    define_draw_fullscreen :disk_out,  ?7, 1, 2
    define_draw_fullscreen :swap_in,   ?7, 2, 2
    define_draw_fullscreen :swap_out,  ?7, 3, 2

    define_draw_subwindow :cpu,        1, 1, 0, 0, true
    define_draw_subwindow :loadavg_1,  3, 1, 0, 0
    define_draw_subwindow :loadavg_5,  3, 1, 1, 0
    define_draw_subwindow :loadavg_15, 3, 1, 2, 0
    define_draw_subwindow :top_cpu,    1, 1, 0, 0, :cpu
    define_draw_subwindow :top_mem,    1, 1, 0, 0, :vm_rss
    define_draw_subwindow :mem,        2, 1, 0, 0
    define_draw_subwindow :swap,       2, 1, 1, 0
    define_draw_subwindow :net_recv,   2, 1, 0, 0, true
    define_draw_subwindow :net_sent,   2, 1, 1, 0, true
    define_draw_subwindow :disk_in,    2, 2, 0, 0
    define_draw_subwindow :disk_out,   2, 2, 1, 0
    define_draw_subwindow :swap_in,    2, 2, 0, 1
    define_draw_subwindow :swap_out,   2, 2, 1, 1
    #
    ###########################################################################
    
    ###########################################################################
    #
    define_draw_loadavg 1
    define_draw_loadavg 5
    define_draw_loadavg 15

    define_loadavg_string_of 1
    define_loadavg_string_of 5
    define_loadavg_string_of 15
    #
    ###########################################################################

    ###########################################################################
    #
    define_draw_top :cpu
    define_draw_top :mem

    define_draw_top_proc_detail :cpu
    define_draw_top_proc_detail :mem
    #
    ###########################################################################

    ###########################################################################
    #
    define_draw_mem :mem
    define_draw_mem :swap

    define_mem_string_of :mem
    define_mem_string_of :swap
    #
    ###########################################################################

    ###########################################################################
    #
    define_draw_net :recv
    define_draw_net :sent

    define_draw_net_of :recv
    define_draw_net_of :sent

    define_net_string_of :recv
    define_net_string_of :sent
    #
    ###########################################################################

    ###########################################################################
    #
    define_draw_vm :disk, :in
    define_draw_vm :disk, :out
    define_draw_vm :swap, :in
    define_draw_vm :swap, :out

    define_vm_string_of :disk, :in,  "Disk Read"
    define_vm_string_of :disk, :out, "Disk Write"
    define_vm_string_of :swap, :in,  "Swap Read"
    define_vm_string_of :swap, :out, "Swap Write"
    #
    ###########################################################################
end
