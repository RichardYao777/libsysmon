#!/usr/bin/env ruby

require 'info'
require 'state'
require 'main_window'
require 'public'

def init
    Console.init

    trap('HUP') { exit }
    trap('TERM') { exit }
    trap('INT') { exit }
end

begin
    init

    last = Time.now.to_f
    Info.instance.init
    MainWindow.instance.refresh
    first = true
    refresh_interval = 0.5
    loop do
        begin
            now = Time.now.to_f
            refresh_interval = Public.instance.refresh_interval unless first
            if now-last > refresh_interval
                last = now
                Info.instance.refresh
                MainWindow.instance.refresh
                first = false if first
            end

            action = State.instance.handle_input(Console::getch)
            case action
            when State::NOTHING
            when State::QUIT
                break
            when State::REFRESH
                MainWindow.instance.refresh
            else
                MainWindow.instance.refresh_bottom
            end
        rescue SystemExit
            break
        #rescue Exception
        end
    end
ensure
    Console.close
end
