module SessionHelper
  def session_header
    if current_user
      render :partial => "shared/logged_in_menu"
    else
      render :partial => "shared/logged_out_menu"
    end
  end
end