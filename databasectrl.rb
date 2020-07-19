
require 'active_record'

set :environment, :production

set :sessions,
  secret: 'xxx',
  expire: 600

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class User < ActiveRecord::Base
  has_many :reservations
  belongs_to :department
end

class Reservation < ActiveRecord::Base
  belongs_to :user
  belongs_to :room
  belongs_to :period
end

class Repeatrsv < ActiveRecord::Base
  belongs_to :user
  belongs_to :room
  belongs_to :period
end

class Rsvtype < ActiveRecord::Base
end

class Room < ActiveRecord::Base
end

class Period < ActiveRecord::Base
end

class Department < ActiveRecord::Base
  has_many :users
end