class OpenFile
    attr_reader :pid, :fds

    def initialize(pid)
        @pid = pid
        @fds = {}

        Dir["/proc/#{pid}/fd/*"].each do |fd|
            begin
                link = File.readlink(fd)
                ftype = File.stat(fd).ftype.to_sym
            rescue
                next
            end

            if fd =~ /.*\/(.+)$/
                @fds[$1.to_i] = [link, ftype]
            end
        end

        #each do |k, v|
        #    p k, v
        #end
    end

    def each
        @fds.keys.sort.each do |key|
            yield key, *@fds[key]
        end
    end

    def count
        @fds.size
    end
end

#OpenFile.new "self"
