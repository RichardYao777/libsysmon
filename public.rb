require 'singleton'

class Public
    include Singleton

    attr_reader :refresh_interval

    def initialize
        @refresh_interval = 3
    end

    def faster_interval
        @refresh_interval = @refresh_interval + 1
    end

    def slower_interval
        @refresh_interval = @refresh_interval - 1 if @refresh_interval > 1
    end
end
