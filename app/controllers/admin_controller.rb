class AdminController < ApplicationController
  require_dependency "wikiuser"

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
      if user = validates?(username,md5pass)
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

  # Return WikiUser object if the username and md5password match. Else false.
  def validates?(username,md5password)
    case Garden.auth_method
    when :dummy
      validates_dummy?(username,md5password)
    when :wiki
      validates_wiki?(username,md5password)
    else
      false
    end
  end
  
  def validates_dummy?(username,md5password)
    username=sanitize_username(username)
    if username=="Joe" && md5password=="5ebe2294ecd0e0f08eab7690d2a6ee69"
      u=WikiUser.new
      u.email=""
      u.id="1"
      u.name="Joe"
      u.real_name="Joe User"
      u.status="sysop"
      return u
    else
      false
    end
  end

  def validates_wiki?(username,md5password)
    require 'rubygems'
    require 'mysql'
    username=sanitize_username(username)
    raise ScriptError, "Please set Garden.localsettings_php" unless Garden.localsettings_php
    string=File.read(Garden.localsettings_php)
    string =~ /^\s*\$wgDBserver\s*=\s*"(.*?)"/
    @dbserver=$1
    string =~ /^\s*\$wgDBname\s*=\s*"(.*?)"/
    @dbname=$1
    string =~ /^\s*\$wgDBuser\s*=\s*"(.*?)"/
    @dbuser=$1
    string =~ /^\s*\$wgDBpassword\s*=\s*"(.*?)"/
    @dbpassword=$1
    m = Mysql.new(@dbserver,@dbuser,@dbpassword,@dbname)
    result=m.query("SELECT * from user")
    result.each_hash do |row|
      if row['user_name']==username
        if row['user_password']==Digest::MD5.hexdigest(row['user_id']+"-"+md5password)
          u=WikiUser.new
          u.email=row['user_email']
          u.id=row['user_id']
          u.name=row['user_name']
          u.real_name=row['user_real_name']
          u.status=row['user_rights']
          return u
        else
          false # incorrect password
        end
      end
      false
    end
    false
  end

  def sanitize_username(name)
    return "" if name.blank?
    name=name[0].chr.capitalize + name[1..-1]
    name.gsub(/_/, ' ')
  end

end
