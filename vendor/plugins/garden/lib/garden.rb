# Garden


module Garden
  mattr_accessor :use_db
  mattr_accessor :auth_method
  mattr_accessor :localsettings_php
  self.use_db = true
  self.auth_method = :wiki
end



class ActionController::Base
  def logged_in?
    session[:user] != nil
  end
  def sysop?
    logged_in? && session[:user].sysop?
  end
  def bureaucrat?
    logged_in? && session[:user].bureaucrat?
  end
  
end
