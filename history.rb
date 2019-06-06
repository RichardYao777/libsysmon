class History
    def initialize(base=nil, capacity=600)
        @data = []
        @capacity = capacity
        @base = base
    end

    def base=(base)
        @base = base
    end

    def <<(data)
        @data << data
        @data.shift if @data.size > @capacity
    end

    def value(index)
        @data[index]
    end

    def last
        @data.last
    end

    def size
        @data.size
    end

    def empty?
        size == 0
    end

    def last_of(last)
        last = @data.size if last > @data.size
        @data[(@data.size-last)..-1]
    end

    def min
        @data.min
    end

    def max
        @data.max
    end

    def base
        @base.nil? ? max : @base
    end

    def min_of(last)
        last_of(last).min
    end

    def max_of(last)
        last_of(last).max
    end

    def base_of(last)
        @base.nil? ? max_of(last) : @base
    end

    def each
        @data.each do |x|
            yield x
        end
    end

    def each_of(last)
        last = @data.size if last > @data.size
        (@data.size-last).upto(@data.size-1) do |index|
            yield @data[index]
        end
    end

    def each_of_with_index(last)
        last = @data.size if last > @data.size
        (@data.size-last).upto(@data.size-1) do |index|
            yield @data[index], index
        end
    end

    def look_back(last)
        last = @data.size if last > @data.size
        (@data.size-1).downto(@data.size-last) do |index|
            yield @data[index]
        end
    end

    def look_back_with_index(last)
        last = @data.size if last > @data.size
        (@data.size-1).downto(@data.size-last) do |index|
            yield @data[index], index
        end
    end
end
