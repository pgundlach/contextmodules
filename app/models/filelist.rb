class Filelist < ActiveRecord::Base
  set_table_name "files"
  belongs_to :package
  acts_as_list :scope => :package_id
end
