require 'ncurses'

class ConsoleString
    attr_accessor :string, :center, :color

    def initialize(string, center=false, color=-1)
        @string = string
        @center = center
        @color = color
    end
end

class Console
    def self.wnd
        Ncurses.stdscr
    end

    def self.init
        Ncurses.initscr
        Ncurses.start_color
        Ncurses.use_default_colors
        Ncurses.init_pair(Ncurses::COLOR_BLACK,   Ncurses::COLOR_BLACK, -1)
        Ncurses.init_pair(Ncurses::COLOR_RED,     Ncurses::COLOR_RED, -1)
        Ncurses.init_pair(Ncurses::COLOR_GREEN,   Ncurses::COLOR_GREEN, -1)
        Ncurses.init_pair(Ncurses::COLOR_YELLOW,  Ncurses::COLOR_YELLOW, -1)
        Ncurses.init_pair(Ncurses::COLOR_BLUE,    Ncurses::COLOR_BLUE, -1)
        Ncurses.init_pair(Ncurses::COLOR_MAGENTA, Ncurses::COLOR_MAGENTA, -1)
        Ncurses.init_pair(Ncurses::COLOR_CYAN,    Ncurses::COLOR_CYAN, -1)
        Ncurses.init_pair(Ncurses::COLOR_WHITE,   Ncurses::COLOR_WHITE, -1)
        Ncurses.cbreak
        Ncurses.noecho
        Ncurses.timeout(100)
        Ncurses.keypad(Ncurses.stdscr, true)
    end

    def self.close
        Ncurses.clear
        Ncurses.refresh
        Ncurses.echo
        Ncurses.nocbreak
        Ncurses.endwin
    end

    def self.getmaxyx(wnd=Ncurses.stdscr)
        h = []
        w = []
        wnd.getmaxyx(h, w)
        return h[0], w[0]
    end

    def self.reverse_on
        Ncurses.attron(Ncurses::A_REVERSE)
    end

    def self.reverse_off
        Ncurses.attroff(Ncurses::A_REVERSE)
    end

    def self.clear
        Ncurses.clear
    end

    def self.refresh
        Ncurses.refresh
    end

    def self.getch
        c = Ncurses::getch
        c == Ncurses::ERR ? nil : c
    end

    def self.draw_char(x, y, ch, wnd=Ncurses.stdscr)
        Ncurses.wmove(wnd, y, x)
        Ncurses.wdelch(wnd)
        Ncurses.winsch(wnd, ch)
    end

    def self.draw_color_char(x, y, ch, color, wnd=Ncurses.stdscr)
        Ncurses.wcolor_set(wnd, color, 0);
        Ncurses.wmove(wnd, y, x);
        Ncurses.wdelch(wnd);
        Ncurses.winsch(wnd, ch);
    end

    def self.draw_h_line(x, y, w, ch, color=-1, wnd=Ncurses.stdscr)
        Ncurses.wcolor_set(wnd, color, 0);
        Ncurses.mvwhline(wnd, y, x, ch, w)
    end

    def self.draw_v_line(x, y, h, ch, color=-1, wnd=Ncurses.stdscr)
        Ncurses.wcolor_set(wnd, color, 0);
        Ncurses.mvwvline(wnd, y, x, ch, h)
    end

    def self.draw_axis(x, y, w, h, color=-1, hc=?_, vc=?|, wnd=Ncurses.stdscr)
        draw_h_line(x, y+h-1, w, hc, color, wnd);
        draw_v_line(x, y,     h, vc, color, wnd);
    end

    def self.draw_box(x, y, w, h, color=-1, hc=?_, vc=?|, wnd=Ncurses.stdscr)
        draw_h_line(x+1,   y,     w-2, hc, color, wnd)
        draw_h_line(x+1,   y+h-1, w-2, hc, color, wnd)
        draw_v_line(x,     y+1,   h-1, vc, color, wnd)
        draw_v_line(x+w-1, y+1,   h-1, vc, color, wnd)
    end

    def self.draw_string(x, y, w, s, center=false, color=-1, standout=false, wnd=Ncurses.stdscr)
        Ncurses.wcolor_set(wnd, color, 0);

		Ncurses.standout() if standout

        if s.size > w
            Ncurses.mvwaddnstr(wnd, y, x, s, w)
        else
            x += (w-s.size)/2 if center
            Ncurses.mvwaddstr(wnd, y, x, s)
        end

		Ncurses.standend() if standout
    end

    def self.draw_strings(x, y, w, h, strings, center=false, color=-1, standout=false, wnd=Ncurses.stdscr)
        h = [strings.size, h].min-1
        0.upto(h) do |n|
            draw_string(x, y+n, w, strings[n], center, color, standout, wnd)
        end
    end

    def self.draw_strings2(x, y, w, h, strings, wnd=Ncurses.stdscr)
        h = [strings.size, h].min-1
        0.upto(h) do |n|
            draw_string(x, y+n, w, strings[n].string, strings[n].center, strings[n].color, standout, wnd)
        end
    end
end
