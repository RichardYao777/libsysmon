require 'singleton'

class User
    include Singleton

    def initialize
        @users = {}
        @groups = {}

        parse_etc_passwd
        parse_etc_group
    end

    def user(uid)
        @users[uid]
    end

    def group(gid)
        @groups[gid]
    end

    private

    def parse_etc_passwd
        IO.foreach("/etc/passwd") do |line|
            if line =~ /^(.+):x:(\d+):/
                @users[$2.to_i] = $1
            end
        end
    end

    def parse_etc_group
        IO.foreach("/etc/group") do |line|
            if line =~ /^(.+):x:(\d+):/
                @groups[$2.to_i] = $1
            end
        end
    end
end
