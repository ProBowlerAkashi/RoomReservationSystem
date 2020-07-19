# -*- coding: utf-8 -*-
require 'digest/sha2'
require 'sinatra'
require 'time'
require 'csv'
require 'active_record'
require 'date'
require './helpers/auth.rb'
require './helpers/reserve.rb'
require './databasectrl.rb'

helpers Auth, Reserve

get '/' do
  puts "hello"
  if session[:login_flag] == true
    redirect '/index'
  else
    session[:failure] = false
    redirect '/login'
  end
end

get '/login' do
  puts session[:failure]
  @log = session[:failure]
  erb :loginscr
end 

post '/auth' do
  username = params[:user]
  userpass = params[:pass]

  #Log in
  begin
    current_account = User.find(username)
  rescue => err_obj
    puts "account nf"
    redirect '/failure'
  end

  result = check_user(current_account, username, userpass)
  case result
    when 0; redirect '/'
    when -1; redirect '/failure'
    when -2; exit -2
    else; exit -3
  end
end

get '/failure' do
  #login failure
  session[:login_flag] = false
  session[:failure] = true
  redirect '/login'
end

get '/logout' do
  #Log out
  session.clear
  erb :logout
end

get '/register' do
  #sign up
  @department = Department.all.to_a
  erb :registerscr  
end

get '/superregister' do
  #Sign up as Super User(hidden)
  erb :suregister
end

post '/susignup' do
  #new user addition
  begin #User id was already used
    n = User.find(params[:nuser])
  rescue #User id is not used
    session[:passincorrect] = false
    session[:userexist] = false
    password = params[:npass]
    corrpass = params[:cpass]
    if (password != corrpass)
      session[:passincorrect] = true
      redirect '/superregister'
    end

    set_new_user( 
      params[:nuser], params[:nname], params[:dept].to_i, 
      params[:grade], password, params[:permission]
    )

    session[:login_flag] = false
    redirect '/signed'
  end
  session[:userexist] = true
  redirect '/superregister'
end

post '/stdsignup' do
  #new user addition
  begin #User id was already used
    n = User.find(params[:nuser])
  rescue #User id is not used
    session[:passincorrect] = false
    session[:userexist] = false
    password = params[:npass]
    corrpass = params[:cpass]
    if (password != corrpass)
      session[:passincorrect] = true
      redirect '/register'
    end
    set_new_user(
      params[:nuser], params[:nname], params[:dept].to_i, 
      params[:grade], password, 2
    )
    session[:login_flag] = false
    redirect '/signed'
  end
  session[:userexist] = true
  redirect '/register'
end

get '/signed' do
  #sign up succeed
  erb :signed
end

get '/index' do
  @periods = Period.all
  @rooms = Room.all
  @users = User.all
  @now = Time.new
  period_now = 0

  case(session[:usertype])
    when 2 then
      @rsvtype = 3 
    when 1 then 
      @rsvtype = 4
    else
      @rsvtype = 0
  end
  @reservation = Reservation.where(rsv_date: @now.strftime("%Y-%m-%d"))
  @my_rsv = Reservation.where(user_id: session[:userid]).where('rsv_date >= ?', @now.strftime("%Y-%m-%d")).order(rsv_date: :asc).order(period_id: :asc)
  @color, @rsvby = make_table(Room.count,Period.count,@reservation)
  @periods.each do |p|
    period_now = p.id if (p.period_char < @now.strftime("%H:%M"))
  end 
  erb :index
end

get '/lesson' do
  @period = Period.all
  @room = Room.all
  
  erb :lessonrsv
end

get '/sushowrsv' do
  @periods = Period.all
  @rooms = Room.all
  @rsvtypes = Rsvtype.all

  @repeat_rsv = Repeatrsv.where(user_id: session[:userid])
  @current_rsv = Reservation.where(user_id: session[:userid], repeat: false)

  session[:before] = '/sushowrsv'
  erb :sushowrsv
end
  
get '/sureserveform' do
  @period = Period.all
  @room = Room.all
  @rsvtype = Rsvtype.all

  erb :sureserve
end

get '/sucsvreserve' do
  # make reserve in csv format
  erb :sucsvreserve
end 

post '/suconfirm' do
  session[:params] = params
  session[:before] = '/suconfirm'

  redirect '/suconfirm'
end

post '/sudelete' do  
  rmid = params[:roomid].to_i
  pdid = params[:periodid].to_i
  length = params[:length].to_i
  rsvdate = params[:rsvdate]
  wday = params[:wday].to_i
  expired = params[:expired]
  if params[:repeat] == "1"
    expired_day = Date.new(expired[0..3].to_i, expired[5..6].to_i, expired[8..9].to_i) 
  end
  current_rsv = []

  if(params[:delall])
    repeat_rsv = Repeatrsv.where(room_id: rmid, rsv_wday: wday, period_id: pdid..pdid+length)
    repeat_rsv.destroy_all

    day.step(expired_day, 7) do |t|
      puts "pin2"
      current_rsv = Reservation.where(room_id: rmid, rsv_date: t.strftime("%Y-%m-%d"), period_id: pdid)
      current_rsv.destroy_all
    end
    current_rsv.destroy_all
  elsif(params[:repeat])
    puts "pin0"
    today = Date.today
    day = today + ((wday - today.wday) % 7)
    expired_day = Date.new(expired[0..3].to_i, expired[5..6].to_i, expired[8..9].to_i)
    repeat_rsv = Repeatrsv.where(room_id: rmid, rsv_wday: wday, period_id: pdid)
    puts "repeat rsv = #{repeat_rsv.to_a}"
    repeat_rsv.destroy_all

    puts "pin1"

    day.step(expired_day, 7) do |t|
      puts "pin2"
      current_rsv = Reservation.where(room_id: rmid, rsv_date: t.strftime("%Y-%m-%d"), period_id: pdid)
      current_rsv.destroy_all
    end

  else
    current_rsv = Reservation.where(room_id: rmid, rsv_date: rsvdate, period_id: pdid)
    current_rsv.destroy_all

  end
  redirect session[:before]
end

get '/suconfirm' do
  params = session[:params]
  @periods = Period.all
  @rooms = Room.all
  @rsvtypes = Rsvtype.all
  @rsvtype = params[:rsvtype].to_i
  @name = params[:name]
  @rmid = params[:roomid].to_i
  @pdid = params[:periodid].to_i
  @repeat = params[:repeat]
  @length = params[:length].to_i
  @date = params[:rsvdate]
  @expired = params[:expired].to_s
  @wday = params[:wday].to_i
  @today = Date.today
  if params[:repeat] == "1"
    @expired_day = Date.new(@expired[0..3].to_i, @expired[5..6].to_i, @expired[8..9].to_i) 
  end
  @day = @today + ((@wday - @today.wday) % 7)
  @current_rsv = []
   
  puts "params = #{params}"

  puts "request confirm suser reservation"
  puts "@day = #{@day}"

  #重複検索
  @repeat_rsv = Repeatrsv.where(room_id: @rmid, rsv_wday: @wday, period_id: @pdid..@pdid+@length)
  puts "repeat_rsv is not exist? = #{@repeat_rsv.to_a.empty?}"
  puts "repeat_rsv = #{@repeat_rsv.to_a}"

  if params[:repeat] == "1"
    @day.step(@expired_day, 7) do |t|
      temp = Reservation.where(room_id: @rmid, period_id: @pdid..@pdid+@length, rsv_date: t.strftime("%Y-%m-%d"), repeat: false)
      @current_rsv = @current_rsv + temp
    end
  else
    @current_rsv = Reservation.where(room_id: @rmid, period_id: @pdid..@pdid+@length, rsv_date: @date, repeat: false)
  end
  puts "current_rsv is not exist? = #{@current_rsv.to_a.empty?}"
  puts "current_rsv = #{@current_rsv.to_a}"

  session[:before] = '/suconfirm'
  erb :suconfirm
end

post '/sureserve' do
  puts "params = #{params}"
  @periods = Period.all
  @rooms = Room.all
  @rmid = params[:roomid].to_i
  @expired = params[:expired].to_s
  @pdid = params[:periodid].to_i
  @length = params[:length].to_i
  @wday = params[:wday].to_i
  @today = Date.today
  @now = Time.now
  @day = @today + ((@wday - @today.wday) % 7)
  if params[:repeat] == "1"
    @expired_day = Date.new(@expired[0..3].to_i, @expired[5..6].to_i, @expired[8..9].to_i) 
  end
  @current_rsv = []


  if (@current_rsv.to_a.empty?) #Make New Reservation
    if(params[:repeat] == '1') # repeatable 
      puts "Notice - create new Reservation"
      for loop in @pdid..(@pdid+@length) do
          rsv = set_new_repeatrsv(
            @now.strftime("%Y%m%d%H%M%S"),
            session[:userid], params[:rsvtype], params[:name], @rmid,
            params[:wday], loop, @expired_day.strftime("%Y-%m-%d")
          )
      end

      @day.step(@expired_day, 7) do |t|
        for loop in @pdid..(@pdid+@length) do
          ActiveRecord::Base.transaction do
            set_new_reserve(
              @now.strftime("%Y%m%d%H%M%S"),
              session[:userid], params[:rsvtype], params[:name], @rmid,
              t.strftime("%Y-%m-%d"), loop, true
            )
          end
        end
      end
    else # Non Repeat
      for loop in @pdid..(@pdid+@length) do
        ActiveRecord::Base.transaction do
          set_new_reserve(
            @now.strftime("%Y%m%d%H%M%S"),
            session[:userid], params[:rsvtype], params[:name], @rmid,
            params[:rsvdate], loop,
          )
        end
      end
    end
  else
    erb :rsvfailure
  end
  
  puts "params = #{params}"
  redirect '/'
end

post '/sucsvupload' do
  @time = Time.now

  puts "file = #{params[:csvfile]}"

  if params[:csvfile] #if file uploaded
    save_path = "./public/csv/#{@time.strftime("%Y%m%d%H%M%S")}.csv"
    File.open(save_path, 'wb') do |f|
      g = params[:csvfile][:tempfile]
			f.write g.read
    end

    CSV.foreach(save_path) do |row|
      
    end
    redirect '/'
    
  else #file missed
    session[:uploadfailure] = true
    redirect '/sucsvreserve'
  end
end

post '/reserve' do
  @periods = Period.all
  @rooms = Room.all
  @rmid = params[:roomid]
  @pdid = params[:periodid]
  period_now = 0
  @t = Time.new

  #重複検索
  current_rsv = Reservation.where(room_id: @rmid, period_id: @pdid, rsv_date: params[:rsvdate])
  puts "current_rsv is not exist? = #{current_rsv.to_a.empty?}"
  puts "current_rsv = #{current_rsv.to_a}"

  @periods.each do |p|
    period_now = p.id if (p.period_char < @t.strftime("%H:%M"))
  end 

  begin 
    ActiveRecord::Base.transaction do
      Reservation.where(user_id: session[:userid], rsv_type: '3').where("period_id < ?", period_now).destroy_all
    end # Commit
  rescue #Roleback
    puts "Error - Cannot Destroy old records"
  end
  @own_rsv = Reservation.where(user_id: session[:userid], rsv_date: @t.strftime("%Y-%m-%d"), rsv_type: 3).order(:period_id)

  puts "own_rsv length = #{@own_rsv.to_a.length}"
  puts "own_rsv = #{@own_rsv.to_a}"

  if (@own_rsv.to_a.length < 2)
    if (current_rsv.to_a.empty?) #Make New Reservation
      puts "Notice - create new Reservation"
      num = 0
      flag = true
      ActiveRecord::Base.transaction do
        rsv = set_new_reserve(
          @t.strftime("%Y%m%d%H%M%S"),
          session[:userid], params[:rsvtype], params[:name], @rmid,
          params[:rsvdate], @pdid
        )
      end

      redirect '/index'
    else
      erb :rsvfailure
    end
  else
    erb :rsvtoomuch
  end 
end

post '/delete' do
  rmid = params[:roomid]
  pdid = params[:periodid]
  date = params[:rsvdate]
  
  current_rsv = Reservation.where(room_id: rmid).where(rsv_date: date).find_by(period_id: pdid)
  current_rsv.destroy

  redirect '/'
end

post '/replace' do
  t = Time.now
  ormid = params[:froomid].to_i
  opdid = params[:fperiodid].to_i
  rmid = params[:roomid].to_i
  pdid = params[:periodid].to_i
  
  puts "params = #{ormid},#{opdid},#{rmid},#{pdid}"

  old_rsv = Reservation.where(room_id: ormid, rsv_date: t.strftime("%Y-%m-%d")).find_by(period_id: opdid)
  puts "old_rsv = #{old_rsv}"
  old_rsv.destroy

  current_rsv = Reservation.where(room_id: rmid, period_id: pdid, rsv_date: t.strftime("%Y-%m-%d"))
  puts "current_rsv is not exist? = #{current_rsv.to_a.empty?}"
  puts "current_rsv = #{current_rsv.to_a}"

  if (current_rsv.to_a.empty?) #Make New Reservation
    puts "Notice - create new Reservation"
    t = Time.new
    num = 0
    flag = true
    
    rsv = set_new_reserve(
      t.strftime("%Y%m%d%H%M%S#{num.to_s.rjust(2,'0')}"),
      session[:userid], params[:rsvtype], User.find(session[:userid]).user_name, rmid,
      t.strftime("%Y-%m-%d"), pdid
    )
    rsv.save

    redirect '/index'
  else
    erb :rsvfailure
  end
end