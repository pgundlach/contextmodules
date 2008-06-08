require File.dirname(__FILE__) + '/../test_helper'
require 'module_controller'

# Re-raise errors caught by the controller.
class ModuleController; def rescue_action(e) raise e end; end

class ModuleControllerTest < Test::Unit::TestCase
	def setup
		@controller = ModuleController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end


	def test_routing
		assert_routing("foo/bar", :controller => "application", :action => "routing_mismatch", :name=>["foo", "bar"]) 
	end

end
