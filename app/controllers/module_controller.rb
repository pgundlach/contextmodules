require 'fileutils'


class ModuleController < ApplicationController
  before_filter :authorize, :only => [:update, :add_revision, :edit, :update_revision]

  def new
    @sidebar="sidebar_index"
    @package = Package.new
    @keywords = Keyword.find(:all)
    @author = Author.find(session[:uid])
  end

  def create
    @sidebar="sidebar_detail"
    @package = Package.new(params[:package])
    
    # Processing ModuleController#create (for 82.95.203.226 at 2009-11-04 08:46:12) [POST]
    # Parameters: {"commit"=>"Create", "package"=>{"indistrib"=>"0", "shortname"=>"", "name"=>"Bib manual", "syncwithctan"=>"0",
    # "ingarden"=>"1", "description"=>"", "license_id"=>"1", "filename"=>"", "ctan"=>"", "author_id"=>"4", "comment"=>"", "short_
    # desc"=>"The manual for the bib module (that is now in the core distribution)"}, "keywords"=>["14"]}
    # NoMethodError (undefined method `[]' for nil:NilClass):
    #   /app/controllers/module_controller.rb:17:in `create'
    # ...
    # therefore commented this line:
    # @package.author=Author.find(params[:author][:id])
    logger.info "Author=#{@package.author}"
    if params[:keywords]
      @package.keywords=Keyword.find(params[:keywords])
    end
    
    if @package.save
      flash[:notice] = 'Module was successfully created.'
      redirect_to "/#{@package.shortname}"
    else
      render :action => 'new'
    end
  end
  
  
  def authorize
    @package=Package.find(params[:id])
    @may_edit=is_admin? || @package.author.id==session[:uid]
  end
  def index
    @sidebar="sidebar_index"
    @packages=Package.find(:all, :order => "name asc")
  end
  def detail
    @sidebar="sidebar_detail"
    @package=Package.find_by_shortname(params[:name])
    author = @package.author
    @authorname = author ? author.name : "unknown"
    unless @package
      flash[:notice]="No such module: #{params[:name]}"
      redirect_to :action => "index"
      return
    end
    @may_edit=is_admin? || @package.author.id==session[:uid]
  end
  def ownmodules
    @sidebar="sidebar_index"
    a=Author.find(session[:uid])
    @packages=a.packages
    if @packages.empty?
      flash[:notice]="No modules found"
      redirect_to :action=> "index"
      return
    end
    render :action => "index"
  end
  def edit
    @sidebar="sidebar_detail"
    @keywords=Keyword.find(:all,:order=>"keyword asc")
    @package_keywords=@package.keywords.collect { |kw| kw.id }
  end
  def add_revision
    @sidebar="sidebar_detail"
  end
  def update
    @sidebar="sidebar_detail"
    if params[:keywords]
      @package.keywords=Keyword.find(params[:keywords])
    end
    
    if @package.update_attributes(params[:package])
      flash['notice'] = 'Module was successfully updated.'
      redirect_to "/#{@package.shortname}"
    else
      render :action => 'edit'
    end
  end
  def update_revision
    unless @may_edit
      flash[:notice] = 'You are not the author'
      redirect_to :action => "detail", :name => @package.shortname
      return
    end
    uploaded_file=params["package"]['file']
    unless uploaded_file and uploaded_file != ""
      flash[:notice] = 'No file selected.'
      redirect_to :action => "detail", :name => @package.shortname
      return
    end
    # check if this is a zip
    original_filename=uploaded_file.original_filename
    unless original_filename =~ /\.zip$/
      flash[:notice] = 'Need a .zip file for upload'
      redirect_to :action => "detail", :name => @package.shortname
      return
    end
    tmpdir=File.join(UPLOADDIR,@package.filename)
    tmpfilename=File.join(tmpdir,original_filename)
    f=Filelist.new
    f.package=@package
    f.versionnumber=params[:package][:latest_version]

    final_zip_filename=@package.filename + "-" + f.versionnumber + ".zip"
    destfilename=File.join(DLDIR,final_zip_filename)
    logger.info "checking if destfilename (#{destfilename}) already exists "
    if File.exists?(destfilename)
      logger.info "yes"
      flash[:notice] = "Destination already exists - this doesn't look like a new version."
      redirect_to :action => "detail", :name => @package.shortname
      return
    else
      logger.info "no"
    end

    logger.info "copy file #{uploaded_file.path} to #{destfilename}"
    FileUtils::mkdir_p(DLDIR)
#    FileUtils::cp uploaded_file.path, destfilename
    File.open(destfilename,"w") do |file|
        file << uploaded_file.read
   end
    FileUtils::cd(DLDIR) do
      sl=@package.filename+".zip"
      # warning: if sl is not a symlink then
      # test(?l,sl) will fail and thus the next
      # step (create symlink) will fail.
      if test(?f,sl)
        logger.info "removing symlink " + sl
        FileUtils::rm(sl)
      end
      logger.info "creating symlink " + sl
      File.symlink(final_zip_filename,sl)
      
      dir=@package.filename
      if test(?d,dir)
        logger.info "removing directory " + dir
        FileUtils::rm_r(dir)
      end
      logger.info "creating: #{dir}"
      FileUtils::mkdir(dir)
      FileUtils::cd(dir) do
        zip=final_zip_filename
        logger.info "unzipping -n #{zip}"
        begin
          timeout(5) do 
            system(UNZIP + " -n ../" + zip)
          end
        rescue TimeoutError
          flash[:notice] = 'Unzip timeout. (internal error)'
          logger.info "unzip timeout"
          redirect_to :action => "detail", :name => @package.shortname
          return
        end
        logger.info "unzip-status: #{$?}"
        unless $?.success?
          flash[:notice] = 'Unzipping returned with an error'
          redirect_to :action => "detail", :name => @package.shortname
          return
        end
        # This needs testing. In the module t-lilypond-2005.10.08.zip there is a file that 
        # is 600 (./tex/context/third/t-lilypond.tex).
        system("chmod -R a+r .")
      end # leaving dir 'dir'
    end
    # done with dl.contextgarden.net/modules/xyz

    logger.info "now handling CTAN dir"
    # now: ctan
    FileUtils::mkdir_p(CTANDIR)
    FileUtils::cd(CTANDIR) do
      dir=@package.filename
      if test(?d,dir)
        logger.info "removing dir #{dir} in #{CTANDIR}"
        FileUtils::rm_rf(dir)
      end
      FileUtils::mkdir_p(dir)
      FileUtils::cd(dir) do
        logger.info "in #{FileUtils::pwd}"
        logger.info "try unzipping archive: #{destfilename}"
        begin
          timeout(5) do
            cmdline=UNZIP + " " + destfilename + "> /dev/null"
            logger.info "cmdline='#{cmdline}'"
            system(cmdline)
          end
        rescue TimeoutError
          flash[:notice] = 'Unzip timeout.'
          logger.info "unzip timeout"
          redirect_to :action => "detail", :name => @package.shortname
          return
        end
        logger.info "unzip-status: #{$?}"
        unless $?.success?
          flash[:notice] = 'Unzipping (for CTAN) returned with an error'
          redirect_to :action => "detail", :name => @package.shortname
          return
        end
      end
    end # ctandir
    # done with ctan
    flash[:notice]="Package update looks successful"
    f.save
    do_update_rss
    redirect_to :action => "detail", :name => @package.shortname
  end
end
