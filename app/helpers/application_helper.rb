# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def flash_helper
    returning("") do |helpers|
      flash.each do |key, message|
        helpers << content_tag(:div, message, :class => "flash-#{key}")
      end
    end
  end
  
  def session_header
    if current_user
      render :partial => "shared/logged_in_menu"
    else
      render :partial => "shared/logged_out_menu"
    end
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
