class Author < ActiveRecord::Base
  has_many :packages
end
