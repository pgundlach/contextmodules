class AdminController < ApplicationController
  filter_parameter_logging :password
  before_filter :authorize, :except => [:logout, :login]
  
  def authorize
    unless is_admin?
      redirect_to "/"
      false
    end
    true
  end
  def logout
    reset_session
    redirect_to "/"
  end

  def index
    @sidebar="/module/sidebar_index"
    if File.exists?(RSSFILE)
      rssage=File.mtime(RSSFILE)
      packageage=Package.find(:first, :order => "updated_on desc").updated_on
      @rss_needs_update = rssage < packageage
    else
      @rss_needs_update=true
    end
  end

  def news
    @sidebar="/module/sidebar_index"
    @last_login=Author.find(session[:uid]).last_visit
    @packages=Package.find(:all,
                   :conditions => ["updated_on > :last_login",
                                   { :last_login => @last_login }])
    #    render :action=> "index", :layout => "module/index"
    render :template => "module/index"
  end
  
  def update_rss
    do_update_rss
    redirect_to :action => "index"
  end
  def login
    @sidebar="/module/sidebar_index"
    if request.post?
      username=params[:user][:name]
      username=username[0].chr.capitalize + username[1..-1]
      username=username.gsub(/_/, ' ')
      # never play with the unencrypted password
      md5pass=Digest::MD5.hexdigest(params[:user][:password])
      params[:user][:password]=md5pass
      if user=AUTHCLASS.validates?(username,md5pass)
        if a=Author.find_by_wikiname(username)
          flash[:notice] = "Welcome!"
        else
          real_name = if params[:user][:fullname].length > 0
                        params[:user][:fullname]
                      elsif user.real_name && user.real_name.length > 0 
                        user.real_name
                      else
                        user.name
                      end
          a=Author.create(:name=>real_name ,
                          :wikiname=> user.name)
          flash[:notice] = "Welcome #{real_name}"
        end
        # don't look what the regular users ar doing
        session[:uid]=a.id
        logger.info "wikiname: #{a.wikiname}"
        session[:is_admin]=true if user.sysop?
        redirect_to "/"
      else

        flash[:notice] = "Incorrect login"
      end
    else
      # request method == 'get'
      reset_session
    end
  end
end
