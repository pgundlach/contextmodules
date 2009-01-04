class LoginController < ApplicationController
  require 'digest/md5'
  require_dependency "wikiuser"

  def index
    @logged_in = logged_in?
    @return_to = request.env["HTTP_REFERER"] || "/"
  end

  def logout
    session[:user]=nil
    flash[:notice]="Welcome guest."
    redirect_to @return_to || request.env["HTTP_REFERER"] || "/"
  end

  def foo
    render :text => "status: sysop #{sysop?} bureaucrat: #{bureaucrat?}"
  end

  def login
    if request.get?
      redirect_to :action => "index"
      return
    end
    # This is POSTed
    username    = params[:user][:name]
    # never play with unencrypted password - they are sacred
    md5pass     = Digest::MD5.hexdigest(params[:user][:password])
    params[:user][:password]=md5pass
    

    unless wikiuser = validates?(username,md5pass)
      flash[:notice] = "incorrect login"
      redirect_to :action => "index"
      return
    end
    # great user has submitted correct username/password!
    session[:user] = wikiuser
    flash[:notice] = "Logged in as #{wikiuser.name}"
    unless Garden.use_db
      redirect_to params[:return_to]
      return
    end
    # We'll have to look up the user in the DB
    unless User.find_by_wikilogin(username)
      # the user is not in the database yet.
      fn=get_newuser_fullname(wikiuser,params[:user][:fullname])
      u=User.create(:wikilogin => username, :fullname => fn, :last_login => Time.now)
      unless u
        flash[:error] = "Something went wrong while saving the user to the database. Please contact Patrick if the problem persists."
      end
      # OK, the user is logged in and saved in the database
    end
    redirect_to params[:return_to]
    return
  end

  # Heuristic to determine the full name of the user. It is either supplied (param 'fullname')
  # or in the wiki database. Fallback is the short name of the user.
  def get_newuser_fullname(wikiuser,param_fullname)
    if not param_fullname.blank?
      param_fullname
    elsif wikiuser.real_name && wikiuser.real_name.length > 0 
      wikiuser.real_name
    else
      wikiuser.name
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
  
  private

  def sanitize_username(name)
    return "" if name.blank?
    name=name[0].chr.capitalize + name[1..-1]
    name.gsub(/_/, ' ')
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
end