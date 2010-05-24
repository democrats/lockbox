# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  include Authentication
  include ExceptionNotifiable

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  skip_before_filter :require_user, :only => :test_exception_notification

  ActiveScaffold.set_defaults do |config| 
    config.ignore_columns.add [:created_at, :updated_at]
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def test_exception_notification
    raise "EXCEPTION NOTIFICATION TEST" if params[:id] == 'blowup'
    render :text => 'Access Denied'
  end
  
  def render_jsonp(json, options={})
    callback, variable = params[:callback], params[:variable]
    response = begin
      if callback && variable
        "var #{variable} = #{json};\n#{callback}(#{variable});"
      elsif variable
        "var #{variable} = #{json};"
      elsif callback
        "#{callback}(#{json});"
      else
        json
      end
    end
    render({:text => response}.merge(options))
  end
  
end
