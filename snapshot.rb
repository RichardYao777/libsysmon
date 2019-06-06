class Snapshot
    def initialize
        @pre_time = Time.now.to_f
        @cur_time = @pre_time
        @pre_data = {}
        @cur_data = {}
        @pre_data3 = {}
        @cur_data3 = {}
    end

    def update_time
        @pre_time = @cur_time
        @cur_time = Time.now.to_f
    end

    def set(name, value)
        @cur_data[name] = value
    end

    def update(name, value)
        @pre_data[name] = @cur_data[name]
        @cur_data[name] = value
    end

    def set3(type, name, value)
        hash = @cur_data3[type] ||= {}
        hash[name] = value
    end

    def update3(type, name, value)
        pre_hash = @pre_data3[type] ||= {}
        cur_hash = @cur_data3[type] ||= {}

        pre_hash[name] = cur_hash[name]
        cur_hash[name] = value
    end

    def count
        @cur_data3.size
    end

    def get_elapse
        @cur_time - @pre_time
    end

    def per_second(value)
        elapse = get_elapse
        if value.is_a?(Fixnum)
            elapse==0 ? 0 : (value/elapse).to_i
        elsif value.is_a?(Float)
            elapse==0 ? 0 : value/elapse
        else
            raise "Unsupport type: #{value.class}"
        end
    end

    def get(name)
        @cur_data[name]
    end

    def get_i(name)
        get(name).to_i
    end

    def get_f(name)
        get(name).to_f
    end

    def get_changed_i(name)
        pre = @pre_data[name]
        cur = @cur_data[name]
        return 0 if pre.nil? or cur.nil?
        cur.to_i - pre.to_i
    end

    def get_changed_f(name)
        pre = @pre_data[name]
        cur = @cur_data[name]
        return 0.0 if pre.nil? or cur.nil?
        cur.to_f - pre.to_f
    end

    def get_changed_per_second_i(name)
        per_second(get_changed_i(name))
    end

    def get_changed_per_second_f(name)
        per_second(get_changed_f(name))
    end

    def each_type
        @cur_data3.each_key do |key|
            yield key
        end
    end

    def keys
        @cur_data3.keys
    end

    def get3(type, name)
        hash = @cur_data3[type]
        return nil if hash.nil?
        hash[name]
    end

    def get3_i(type, name)
        get3(type, name).to_i
    end

    def get3_f(type, name)
        get3(type, name).to_f
    end

    def get3_changed_i(type, name)
        pre = @pre_data3[type]
        cur = @cur_data3[type]
        return 0 if pre.nil? or cur.nil?
        pre = pre[name]
        cur = cur[name]
        return 0 if pre.nil? or cur.nil?
        cur.to_i - pre.to_i
    end

    def get3_changed_f(type, name)
        pre = @pre_data3[type]
        cur = @cur_data3[type]
        return 0.0 if pre.nil? or cur.nil?
        pre = pre[name]
        cur = cur[name]
        return 0.0 if pre.nil? or cur.nil?
        cur.to_f - pre.to_f
    end

    def get3_changed_per_second_i(type, name)
        per_second(get3_changed_i(type, name))
    end

    def get3_changed_per_second_f(type, name)
        per_second(get3_changed_f(type, name))
    end

    def delete_except(existed)
        unless @pre_data3.nil?
            (@pre_data3.keys-existed).each do |dead|
                @pre_data3.delete(dead)
            end
        end

        unless @cur_data3.nil?
            (@cur_data3.keys-existed).each do |dead|
                @cur_data3.delete(dead)
            end
        end
    end
end
