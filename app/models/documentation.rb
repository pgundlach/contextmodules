class Documentation < ActiveRecord::Base
  set_table_name "documentation"
  belongs_to :package
  def alt
    self[:alt] =="" ? nil : self[:alt]
  end
end
