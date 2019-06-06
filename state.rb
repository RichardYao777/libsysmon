require 'singleton'
require 'console'
require 'main_window'
require 'info'
require 'public'
require 'open_file'

class State
    include Singleton

    NOTHING = 0
    QUIT = 1
    REFRESH = 2

    attr_reader :current_state

    def initialize
        @current_state = StateMain.instance 
    end
    
    def handle_input(ch)
        return nil if ch.nil? 

        case ch
        when Ncurses::KEY_RESIZE
            @current_state.reset_help_position
            REFRESH
        when ?q, ?Q
            QUIT
        when ?h, ?H
        when ?-, ?_
            Public.instance.slower_interval
            NOTHING
        when ?+, ?=
            Public.instance.faster_interval
            NOTHING
        when ?1
            change_state(StateCpu.instance)
        when ?2
            change_state(StateLoadavg.instance)
        when ?3
            change_state(StateTopCpu.instance)
        when ?4
            change_state(StateTopMem.instance)
        when ?5
            change_state(StateMem.instance)
        when ?6
            change_state(StateNet.instance)
        when ?7
            change_state(StateVm.instance)
        when 32 #SPACE 
            change_state(StateMain.instance)
        else
            @current_state.handle_input(ch)
        end
    end

    def change_state(new_state)
        return nil if @current_state == new_state
        @current_state.leave
        @current_state = new_state
        @current_state.enter
        REFRESH
    end
end

class StateBase
    def initialize
        @cur_help_index = 0
        @author = 'Richard Yao'
    end

    def enter
        reset_help_position
    end

    def leave
    end

    def handle_input(ch)
    end

    def reset_help_position
        @cur_help_index = 0
    end

    def help_str
        "Press q to quit, 1..7 to enter sub window, SPACE to return main window, " +
        "-/+ to adjust refresh speed(current speed=#{Public.instance.refresh_interval} sec)"
    end

    def now_str
        now = Time.now
        sprintf "%02d:%02d:%02d", now.hour, now.min, now.sec
    end

    def author_str
        @author
    end

    def draw_bottom(w, h)
        # Draw author
        Console::draw_string(0, h-1, w, author_str, false, Ncurses::COLOR_GREEN)

        # Draw help
        draw_help(author_str.size+1, h-1, w-author_str.size-8-2)

        # Draw time
        Console::draw_string(w-now_str.size, h-1, w, now_str, false, Ncurses::COLOR_YELLOW)
    end

    def draw_help(x, y, w)
        return if w <= 0
        help = help_str

        if @cur_help_index < 0
            Console::draw_string(x-@cur_help_index, y, w,
                                 help[0, @cur_help_index+w], false, Ncurses::COLOR_RED)
        elsif @cur_help_index+w >= help.size
            Console::draw_string(x, y, w, help[@cur_help_index..-1], false, Ncurses::COLOR_RED)
        else
            Console::draw_string(x, y, w, help[@cur_help_index, w], false, Ncurses::COLOR_RED)
        end

        @cur_help_index = @cur_help_index + 1
        @cur_help_index = -w+1 if @cur_help_index > help.size
    end
end

class StateMain < StateBase
    include Singleton

    def refresh(w, h)
        MainWindow.instance.draw_fullscreen_cpu(      w, h)
        MainWindow.instance.draw_fullscreen_loadavg_1(w, h)
        MainWindow.instance.draw_fullscreen_top_cpu(  w, h)
        MainWindow.instance.draw_fullscreen_top_mem(  w, h)
        MainWindow.instance.draw_fullscreen_mem(      w, h)
        MainWindow.instance.draw_fullscreen_swap(     w, h)
        MainWindow.instance.draw_fullscreen_net_recv( w, h)
        MainWindow.instance.draw_fullscreen_net_sent( w, h)
        MainWindow.instance.draw_fullscreen_disk_in(  w, h)
        MainWindow.instance.draw_fullscreen_disk_out( w, h)
        MainWindow.instance.draw_fullscreen_swap_in(  w, h)
        MainWindow.instance.draw_fullscreen_swap_out( w, h)
    end
end

class StateCpu < StateBase
    include Singleton

    def refresh(w, h)
        MainWindow.instance.draw_subwindow_cpu(w, h)
    end
end

class StateLoadavg < StateBase
    include Singleton

    def refresh(w, h)
        MainWindow.instance.draw_subwindow_loadavg_1( w, h)
        MainWindow.instance.draw_subwindow_loadavg_5( w, h)
        MainWindow.instance.draw_subwindow_loadavg_15(w, h)
    end
end

class StateTop < StateBase
    @@sort = [:pid, :ppid, :uid, :gid, :state, :cpu,
        :vm_rss, :vm_size, :vm_rss,
        :vm_share, :vm_peak, :vm_data,
        :priority, :nice, :nlwp, :name]

    attr_reader :is_sort_asc
    attr_accessor :cur_line, :cur_pid

    def initialize
        super

        @sort = 0
        @is_sort_asc = false
        @cur_line = 0
        @cur_pid = 0
    end

    def enter
        super

        @is_sort_asc = false
        @cur_line = 0
        @cur_pid = 0
    end

    def save_state
        [@sort, @is_sort_asc, @cur_line, @cur_pid]
    end

    def restore_state(state)
        @sort, @is_sort_asc, @cur_line, @cur_pid = *state
    end

    def sort_by=(sort_by)
        @@sort.each_with_index do |sort, index|
            if sort == sort_by
                @sort = index
                break
            end
        end
    end

    def sort_by
        @@sort[@sort]
    end

    def goto_previous_sort_by
        @sort = @sort - 1
        @sort = @@sort.size - 1 if @sort < 0 
    end

    def goto_next_sort_by
        @sort = @sort + 1
        @sort = 0 if @sort >= @@sort.size
    end

    def change_sort_direction
        @is_sort_asc = @is_sort_asc ? false : true
    end

    def goto_first_line
        if @cur_line != 0
            @cur_line = 0
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_previous_line
        if @cur_line > 0
            @cur_line = @cur_line - 1
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_previous_page
        if @cur_line > 0
            h, w = Console::getmaxyx
            @cur_line = @cur_line - ((h-4)/2).to_i
            @cur_line = 0 if @cur_line < 0
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_next_line
        if @cur_line + 1 < Info.instance.procs.count
            @cur_line = @cur_line + 1
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_next_page
        if @cur_line + 1 < Info.instance.procs.count
            h, w = Console::getmaxyx
            @cur_line = @cur_line + ((h-4)/2).to_i
            @cur_line = Info.instance.procs.count - 1 if @cur_line >= Info.instance.procs.count
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_last_line
        if @cur_line + 1 != Info.instance.procs.count
            @cur_line = Info.instance.procs.count - 1
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def handle_input(ch)
        case ch
        when ?r, ?R
            change_sort_direction
            State::REFRESH

        when ?{, ?[, Ncurses::KEY_LEFT
            goto_previous_sort_by
            State::REFRESH

        when ?}, ?], Ncurses::KEY_RIGHT
            goto_next_sort_by
            State::REFRESH

        when Ncurses::KEY_HOME
            goto_first_line

        when ?<, ?,, ?k, Ncurses::KEY_UP
            goto_previous_line

        when ?>, ?., ?j, Ncurses::KEY_DOWN
            goto_next_line

        when Ncurses::KEY_END
            goto_last_line

        when Ncurses::KEY_PPAGE
            goto_previous_page

        when Ncurses::KEY_NPAGE
            goto_next_page

        when Ncurses::KEY_ENTER, ?\r, ?\n
            StateOpenFile.instance.pid = @cur_pid
            StateOpenFile.instance.current_state = State.instance.current_state
            StateOpenFile.instance.saved_state = State.instance.current_state.save_state
            State.instance.change_state(StateOpenFile.instance)
        end
    end

    def help_str
        str = super
        str = "#{str}, UP/DOWN/HOME/END/PGUP/PGDN arrows to move current process"
        str = "#{str}, LEFT/RIGHT arrows to move sort field"
        str = "#{str}, r to reverse the sort direction"
    end
end

class StateTopCpu < StateTop
    include Singleton

    def enter
        super

        self.sort_by=:cpu
    end

    def refresh(w, h)
        # Some processes maybe already died
        self.cur_line = Info.instance.procs.count-1 if cur_line >= Info.instance.procs.count
        MainWindow.instance.draw_subwindow_top_cpu(w, h, [sort_by, is_sort_asc, cur_line])
    end
end

class StateTopMem < StateTop
    include Singleton

    def enter
        super

        self.sort_by = :vm_rss
    end

    def refresh(w, h)
        # Some processes maybe already died
        self.cur_line = Info.instance.procs.count-1 if cur_line >= Info.instance.procs.count
        MainWindow.instance.draw_subwindow_top_mem(w, h, [sort_by, is_sort_asc, cur_line])
    end
end

class StateMem < StateBase
    include Singleton

    def refresh(w, h)
        MainWindow.instance.draw_subwindow_mem( w, h)
        MainWindow.instance.draw_subwindow_swap(w, h)
    end
end

class StateNet < StateBase
    include Singleton

    def refresh(w, h)
        MainWindow.instance.draw_subwindow_net_recv(w, h)
        MainWindow.instance.draw_subwindow_net_sent(w, h)
    end
end

class StateVm < StateBase
    include Singleton

    def refresh(w, h)
        MainWindow.instance.draw_subwindow_disk_in( w, h)
        MainWindow.instance.draw_subwindow_disk_out(w, h)
        MainWindow.instance.draw_subwindow_swap_in( w, h)
        MainWindow.instance.draw_subwindow_swap_out(w, h)
    end
end

class StateOpenFile < StateBase
    include Singleton

    attr_accessor :pid, :current_state, :saved_state

    def initialize
        super
        @cur_line = 0
    end

    def enter
        super
        @cur_line = 0
    end

    def goto_first_line
        if @cur_line != 0
            @cur_line = 0
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_previous_line
        if @cur_line > 0
            @cur_line = @cur_line - 1
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_previous_page
        if @cur_line > 0
            h, w = Console::getmaxyx
            @cur_line = @cur_line - ((h-3)/2).to_i
            @cur_line = 0 if @cur_line < 0
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_next_line
        if @cur_line + 1 < @open_file.count
            @cur_line = @cur_line + 1
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_next_page
        if @cur_line + 1 < @open_file.count
            h, w = Console::getmaxyx
            @cur_line = @cur_line + ((h-4)/2).to_i
            @cur_line = @open_file.count - 1 if @cur_line >= @open_file.count
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def goto_last_line
        if @cur_line + 1 != @open_file.count
            @cur_line = @open_file.count - 1
            State::REFRESH
        else
            State::NOTHING
        end
    end

    def handle_input(ch)
        case ch
        when Ncurses::KEY_BACKSPACE, 8
            State.instance.change_state(current_state)
            current_state.restore_state(saved_state)
            State::REFRESH

        when Ncurses::KEY_HOME
            goto_first_line

        when ?<, ?,, ?k, Ncurses::KEY_UP
            goto_previous_line

        when ?>, ?., ?j, Ncurses::KEY_DOWN
            goto_next_line

        when Ncurses::KEY_END
            goto_last_line

        when Ncurses::KEY_PPAGE
            goto_previous_page

        when Ncurses::KEY_NPAGE
            goto_next_page
        end
    end

    def refresh(w, h)
        @open_file = OpenFile.new(pid)
        @cur_line = @open_file.count - 1 if @cur_line >= @open_file.count
        MainWindow.instance.draw_open_file(w, h, pid, @open_file, @cur_line)
    end

    def help_str
        str = super
        str = "#{str}, UP/DOWN/HOME/END/PGUP/PGDN arrows to move current file"
        str = "#{str}, BACKSPACE to return upper window"
    end
end
