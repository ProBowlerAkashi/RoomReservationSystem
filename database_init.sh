rm password.db
sqlite3 password.db < ./database/user_init.sq3
sqlite3 password.db < ./database/period_init.sq3
sqlite3 password.db < ./database/reservate_init.sq3
sqlite3 password.db < ./database/repeatrsv_init.sq3
sqlite3 password.db < ./database/room_init.sq3
sqlite3 password.db < ./database/department_init.sq3