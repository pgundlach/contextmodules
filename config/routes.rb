ActionController::Routing::Routes.draw do |map|
  map.connect '', :controller => "module"
  map.connect '/author/:action', :controller => "author"
  map.connect '/module/:action', :controller => "module"
  map.connect '/license/:action', :controller => "license"
  map.connect '/admin/:action', :controller => "admin"
  map.connect ":name" ,
               :controller => "Module",
               :action => "detail"
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
	map.connect '*name', :controller => "application", :action => "routing_mismatch"
end
