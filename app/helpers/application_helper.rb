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


  def table_helper(collection, fields)
    builder = Builder::XmlMarkup.new
    builder.table(:class => "advocacy-table") do
      builder.thead do |th|
        fields.each do |field|
          if field.is_a?(Symbol)
            th.th(field.to_s.humanize.titleize)
          else
            th.th(field.keys.first.to_s.humanize.titleize)
          end
        end
      end
      collection.each do | element |
        builder.tr(:class => cycle("odd", "even")) do | tr |
          fields.each do | field |
            if field.is_a?(Symbol)
              tr.td(h(element.send(field).to_s))
            else
              tr << "<td>#{field[field.keys.first].call(element)} </td>"

            end
          end
        end
      end
    end
    builder
  end
  

end
