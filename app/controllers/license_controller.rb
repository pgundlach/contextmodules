class LicenseController < ApplicationController
  # make sure that only admins are allowed to deal with the licenses
  before_filter :authorize
  
  # one line to rule 'em all (create methods such as 'index', 'edit' etc.)
  scaffold :license
  
  # if we are not logged in, just display the login page
  def authorize
    if is_admin?
      true
    else
      redirect_to :controller => "admin", :action => "login"
    end
  end

end
