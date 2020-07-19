module Auth
  def check_user(account,user_id,user_pass)
    #Log in 
    if account.algo == "1" #MD5 sum
        passwd_hashed = Digest::MD5.hexdigest(account.salt + user_pass)
    elsif account.algo == "2" #SHA256 sum
        passwd_hashed = Digest::SHA256.hexdigest(account.salt + user_pass)
    else #unknown
        puts "Err...Unknown algorythm was used to hash the passwd"
        return -2
    end
    
    puts "passwd_hashed = " + passwd_hashed
    puts "account.pass = " + account.pass 

    if passwd_hashed == account.pass
        #Log in succeed
        session[:login_flag] = true
        session[:userid] = account.id
        session[:usertype] = account.admin
        session[:failure] = false
        return 0
    else
        #Log in failure
        session[:login_flag] = false
        return -1
    end
  end
  def set_new_user(id, name, dept, grade, pass, admin)
    n = User.new

    str = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    n.id = id
    n.user_name = name
    n.dept_id = dept
    n.grade = grade
    n.salt = (0...40).map { str[rand(str.length)] }.join
    n.pass = Digest::SHA256.hexdigest(n.salt + pass)
    n.algo = "2"
    n.admin = admin
    n.save
  end
end  