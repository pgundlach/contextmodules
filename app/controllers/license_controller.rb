class LicenseController < ApplicationController
  # make sure that only admins are allowed to deal with the licenses
  before_filter :authorize
  
  # See http://contextgarden.lighthouseapp.com/projects/22782/tickets/1-replace-scaffold-from-license_controller
  # one line to rule 'em all (create methods such as 'index', 'edit' etc.)
  # scaffold :license
  
  # if we are not logged in, just display the login page
  def authorize
    if is_admin?
      true
    else
      redirect_to :controller => "admin", :action => "login"
    end
  end

end
