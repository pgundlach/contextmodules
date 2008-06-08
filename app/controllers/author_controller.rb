class AuthorController < ApplicationController
  before_filter :authorize

  def authorize
    is_admin?
  end
  
  def index
    @sidebar="/module/sidebar_index"
    list
    render :action => 'list'
  end

  def list
    @sidebar="/module/sidebar_index"
    @author_pages, @authors = paginate :authors, :per_page => 10
  end

  def show
    @sidebar="/module/sidebar_index"
    @author = Author.find(params[:id])
  end

  def new
    @sidebar="/module/sidebar_index"
    @author = Author.new
  end

  def create
    @sidebar="/module/sidebar_index"
    @author = Author.new(params[:author])
    if @author.save
      flash[:notice] = 'Author was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @sidebar="/module/sidebar_index"
    @author = Author.find(params[:id])
  end

  def update
    @sidebar="/module/sidebar_index"
    @author = Author.find(params[:id])
    if @author.update_attributes(params[:author])
      flash[:notice] = 'Author was successfully updated.'
      redirect_to :action => 'show', :id => @author
    else
      render :action => 'edit'
    end
  end

  def destroy
    @sidebar="/module/sidebar_index"
    Author.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
