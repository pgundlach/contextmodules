class WikiUser
  # The email address if given.
  attr_accessor :email
  # The wiki id.
  attr_accessor :id
  # The login as stored in the database.
  attr_accessor :name
  # The full name (from DB).
  attr_accessor :real_name
  # Status, a String, such as "sysop,bureaucrat"
  attr_accessor :status
  # Return true if the user has sysop status
  def sysop?
    (status =~ /sysop/) != nil
  end
  # Return true if the user has bureaucrat status (= admin)
  def bureaucrat?
    (status =~ /bureaucrat/) != nil
  end
end
