require 'user'

class Numeric
    def to_unit_string
        if self < 1000*1000
            sprintf("%.1fK", self/1024.0)
        elsif self < 1000*1000*1000
            sprintf("%.1fM", self/(1024.0*1024))
        else
            sprintf("%.1fG", self/(1024.0*1024*1024))
        end
    end
end

class Symbol
    def <=>(other)
        self.to_s <=> other.to_s
    end
end

class ProcUtil
    def self.cwd(pid)
        cwd = nil
        begin
            cwd = File.readlink "/proc/#{pid}/cwd"
        rescue
        end

        cwd
    end

    def self.exe(pid)
        exe = nil
        begin
            exe = File.readlink "/proc/#{pid}/exe"
        rescue
        end

        exe
    end

    def self.cmdline(pid)
        cmd = nil

        begin
            File.new("/proc/#{pid}/cmdline").readline.split("\0").each do |arg|
                cmd.nil? ? cmd = arg : cmd = "#{cmd} #{arg}"
            end
        rescue
        end

        cmd
    end
end

class FileUtil
    def self.file_status(fname)
        status = ""

        begin
            stat = File.stat(fname)
            size = stat.size.to_unit_string 
            user = User.instance.user(stat.uid)
            group = User.instance.group(stat.gid)
            mtime = stat.mtime.strftime("%Y/%m/%d %I:%M%p")
            mode = sprintf("%o", stat.mode)
            status = "#{size} #{user}:#{group} mtime=<#{mtime}> mode=#{mode}"
        rescue
        end

        status
    end 
end
