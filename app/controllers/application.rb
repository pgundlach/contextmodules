# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Last Change: Wed Apr  5 23:30:48 2006

class ApplicationController < ActionController::Base

  def is_admin?
    session[:is_admin]==true
  end

  def do_update_rss
    require 'rss/2.0'
    rss=RSS::Rss.new('2.0')
    chan = RSS::Rss::Channel.new
    chan.title = "List of ConTeXt modules and packages"
    chan.description = "List of ConTeXt modules and packages"
    chan.link = "http://modules.contextgarden.net"
    rss.channel = chan

    p=Package.find(:all, :order => ["updated_on desc"])
    p.each do |package|
      item = RSS::Rss::Channel::Item.new
      item.title = package.name
      item.title <<  " (" + package.latest_version  + ")" if package.latest_version
      item.link = "http://modules.contextgarden.net/" + package.shortname
      if package.author and package.author.name then
        item.description = "Author: " + package.author.name
      else
        item.description = "Author: (unknown)"
      end
      if package.in_garden?
        item.description  << "<br/>Current Version: " + (package.latest_version || "")
      end
      if d=package.description
        item.description <<  "<br/><br/>" + d
      end
      item.pubDate = package.updated_on
      chan.items << item
    end
    File.open(RSSFILE,"w") { |file|
      file << rss.to_s
    }
  end

  # def local_request?
  #   false
  # end

  def routing_mismatch
    raise ::ActionController::RoutingError,"URL not supported"
  end

	def rescue_action_in_public(exception)
		case exception
		when ::ActionController::RoutingError
			flash[:notice] = "URL not supported"
		else
			flash[:notice] = "Internal error, please contact pg@contextgarden.net"
		end
		redirect_to :action => "index", :controller => "module"
	end
end
