class DocumentationController < ApplicationController
  before_filter :authorize_with_package, :only => [:index, :new, :create]

  def authorize_with_package
    @package=Package.find(params[:id])
    return true if is_admin?
    return true if @package.author.id==session[:uid]
    false
  end
  def authorize_author
    return true if is_admin?
    unless @package.author.id == session[:uid]
      redirect_to "/"
      return
    end
    return true
  end
  
  def index
    @sidebar="/module/sidebar_detail"
    @docs=@package.documentation
  end
  
  def show
    @sidebar="/module/sidebar_detail"
    @doc = Documentation.find(params[:id])
    @package=@doc.package
    authorize_author
  end
  
  def new
    @doc=Documentation.new
  end
  def edit
    @sidebar="/module/sidebar_detail"
    @doc = Documentation.find(params[:id])
    @package=@doc.package
    authorize_author
  end
  def update
    @sidebar="/module/sidebar_detail"
    @doc = Documentation.find(params[:id])
    @package=@doc.package
    if authorize_author
      if @doc.update_attributes(params[:doc])
        flash[:notice] = 'Documentation was successfully updated.'
        redirect_to :action => 'show', :id => @doc
      else
        render :action => 'edit'
      end
    end
  end
  def create
    @sidebar="/module/sidebar_index"
    @doc = Documentation.new(params[:doc])
    @doc.package=@package
    if @doc.save
      flash[:notice] = 'Doc was successfully created.'
      redirect_to :action => "index", :id => @package
    else
      render :action => 'new'
    end
  end
  def destroy
    @sidebar="/module/sidebar_detail"
    @doc=Documentation.find(params[:id])
    @package=@doc.package
    if authorize_author
      @doc.destroy
      redirect_to :action => "index", :id => @package
    end
  end
end
