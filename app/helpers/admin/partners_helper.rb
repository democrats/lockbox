module Admin::PartnersHelper

  def labeled_show_field(label_text, value)
    
    "<div style=\"clear:both; width:500px;\"><div style=\"float:left;width:200px;\">#{label_text}</div><div style=\"float:left;margin-left:10px;width:290px;\">#{value}</div></div>"
    
    
  end

end
