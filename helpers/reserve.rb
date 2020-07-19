module Reserve
    def make_table(room_count,period_count,reservations) # return color, rsvby table
        color = Array.new(period_count){ Array.new(room_count, "#ffffff") }
        rsvby = Array.new(period_count){ Array.new(room_count, "") }
        for lx in (1..period_count) do
            for ly in (1..room_count) do
                if reservations.where(room_id: ly).where(period_id: lx).any?
                    current_rsv = reservations.where(room_id: ly).find_by(period_id: lx)
                    puts "room = #{ly}, period = #{lx}, type = #{current_rsv.rsv_type.to_i}"
                    puts "reservation = #{current_rsv}"
                    case current_rsv.rsv_type.to_i
                    when 0 # Normal Class
                    color[ly][lx] = "#ffffff"
                    rsvby[ly][lx] = current_rsv.rsv_name
                    when 1 # Normal Lesson          
                    color[ly][lx] = "#00a400"
                    rsvby[ly][lx] = current_rsv.rsv_name
                    when 2 # Charged Lental
                    color[ly][lx] = "#0000ff"
                    rsvby[ly][lx] = "有料レンタル"
                    when 3 # Student Use
                    color[ly][lx] = "#9100d3"
                    rsvby[ly][lx] = current_rsv.rsv_name
                #      @rsvby[ly][lx] = current_rsv.user_id
                    when 4 # Teacher Use
                    color[ly][lx] = "#ff0000"
                    rsvby[ly][lx] = current_rsv.rsv_name + "先生"
                    when 5 # TV Committee
                    color[ly][lx] = "#ff8800"
                    rsvby[ly][lx] = "TV会議"
                    when 6 # Short Course
                    color[ly][lx] = "#cccc00"
                    rsvby[ly][lx] = current_rsv.rsv_name
                    else
                    color[ly][lx] = "#ffffff"
                    rsvby[ly][lx] = current_rsv.rsv_name
                    end
                end
            end
        end
        return color, rsvby
    end

    def set_new_reserve(id, uid, type, name, rid, date, pid, repeat=false) # It needs transaction management
        num = 0

        rsv = Reservation.new
        rsv.id = id + num.to_s.rjust(4,'0')
        rsv.user_id = uid
        rsv.rsv_type = type
        rsv.rsv_name = name
        rsv.room_id = rid
        rsv.rsv_date = date
        rsv.period_id = pid
        rsv.repeat = repeat

        puts "New Reserve = {#{rsv.id},#{rsv.user_id},#{rsv.rsv_type},#{rsv.rsv_name},#{rsv.room_id},#{rsv.rsv_date},#{rsv.period_id}}"
  
        while num.to_i < 10000 #rescue to reservate at the same time
            begin 
                ActiveRecord::Base.transaction do
                    puts "New Reserve has saved - ID:#{rsv.id}"
                    rsv.save
                    num = 10000
                end
            rescue ActiveRecord::StatementInvalid
                num = num + 1
                rsv.id = id + num.to_s.rjust(4,'0')
                puts "Notice - Reservate at the same time"
            end 
        end 
    end

    def set_new_repeatrsv(id, uid, type, name, rid, wday, pid, exp) # It needs transaction management
        num = 0

        rsv = Repeatrsv.new
        rsv.id = id + num.to_s.rjust(2,'0')
        rsv.user_id = uid
        rsv.room_id = rid
        rsv.period_id = pid
        rsv.rsv_type = type
        rsv.rsv_name = name
        rsv.rsv_wday = wday
        rsv.expired = exp

        puts "New Repeat Reservation = {#{rsv.id},#{rsv.user_id},#{rsv.rsv_type},#{rsv.rsv_name},#{rsv.room_id},#{rsv.rsv_wday},#{rsv.period_id}}"
  
        while num.to_i < 100 #rescue to reservate at the same time
            begin 
                ActiveRecord::Base.transaction do
                    puts "New Repeat Reservation has saved - ID:#{rsv.id}"
                    rsv.save
                    num = 100
                end
            rescue ActiveRecord::StatementInvalid
                num = num + 1
                rsv.id = id + num.to_s.rjust(2,'0')
                puts "Notice - Reservate at the same time"
            end 
        end 
    end
end