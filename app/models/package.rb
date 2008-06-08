class Package < ActiveRecord::Base
  belongs_to :license
  belongs_to :author
  has_many :documentation, :foreign_key=> "package_id"
  has_many :files,         :order => "position", :foreign_key=> "package_id", :class_name => "Filelist"
  has_and_belongs_to_many  :keywords
  def url
    return nil unless self[:url]
    self[:url].empty? ? nil : self[:url]
  end
  def short_desc
    return nil unless self[:short_desc]
    self[:short_desc].empty? ? nil : self[:short_desc]
  end
  
  def in_garden?
    self.ingarden==1
  end
  def has_files?
    ! self.files.empty?
  end
  def in_distribution?
    indistrib==1
  end
  # do we have a location on ctan?
  def ctan_loc?
    self.ctan != nil && ! self.ctan.empty?
  end
  def full_filename
    return nil unless self.filename
    return nil unless self.has_files?
    self.filename + "-" + latest_version + ".zip"
  end
  def has_documentation?
    ! self.documentation.empty?
  end

  def has_comment?
    comment && ! comment.empty?
  end

  # Return latest version of the package.
  def latest_version
    files.last && files.last.versionnumber
  end
  def latest_version=(version)
    return if latest_version==version
    f=Filelist.new
    f.package=self
    f.versionnumber=version
    f.save
  end
end
