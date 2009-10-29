# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def flash_helper
    returning("") do |helpers|
      flash.each do |key, message|
        helpers << content_tag(:div, message, :class => "flash-#{key}")
      end
    end
  end

end
