class LabeledBuilder < ActionView::Helpers::FormBuilder
  alias :real_label :label unless method_defined?(:real_label)

  ((field_helpers - %w(check_box radio_button hidden_field label)) + %w(date_select datetime_select) ) .each do |method_name|
    src = <<-end_src
      alias :real_#{method_name} :#{method_name}
      def #{method_name}(field_name, options = {})
        options ||= {}
        label_options = (options[:label_options] || {})
        label_options[:required] = options[:required] if options[:required]
        lbl = options[:label] == '' ? '' : label(field_name, options.delete(:label), label_options)
        help = (options[:help]) ?  @template.content_tag('div', options[:help], :class => 'field-help') : ''
        @template.content_tag('div', lbl + help + super, :class => 'field')
      end
    end_src
    class_eval src, __FILE__, __LINE__
  end

  alias :real_check_box :check_box
  def check_box(field_name, options = {})
    options ||= {}
    label_options = (options[:label_options] || {})
    label_options[:required] = options[:required] if options[:required]
    lbl = options[:label] == '' ? '' : label(field_name, options.delete(:label), label_options)
    help = (options[:help]) ?  @template.content_tag('div', options[:help], :class => 'field-help') : ''
    @template.content_tag('div', lbl + help + super, :class => 'field')
  end

  alias :real_select :select
  src = <<-end_src
    def select(field_name, choices, options = {}, html_options = {})
      options ||= {}
      label_options = (options[:label_options] || {})
      label_options[:required] = options[:required] if options[:required]
      lbl = options[:label] == '' ? '' : label(field_name, options.delete(:label), label_options)
      help = (options[:help]) ?  @template.content_tag('div', options[:help], :class => 'field-help') : ''
      @template.content_tag('div', lbl + help + super, :class => 'field')
    end
  end_src
  class_eval src, __FILE__, __LINE__

  def collection_select(field_name, collection, value_method, text_method, options = {}, html_options = {})
    options ||= {}
    label_options = (options[:label_options] || {})
    label_options[:required] = options[:required]
    lbl = options[:label] == '' ? '' : label(field_name, options.delete(:label), label_options)
    help = (options[:help]) ?  @template.content_tag('div', options[:help], :class => 'field-help') : ''
    @template.content_tag('div', lbl + help + super, :class => 'field')
  end

  def label(field_name, text=nil, options={})
    # reqd = "#{required_icon}" if options[:required] || ((@object && @object.attribute_required?(field_name)) && !options.include?(:required))
    reqd = is_field_required?(field_name, options) ? '' : optional_tag
    text = (text.nil? ? nil : text) || field_name.to_s.humanize.titleize
    real_label(field_name, "#{text}#{reqd}", options)
  end

  def is_field_required?(field_name, options)
    options[:required] || ((@object && @object.respond_to?(:attribute_required?) && @object.attribute_required?(field_name)) && !options.include?(:required))
  end

  def labeled_fields_for(name, *args, &block)
    name = "#{object_name}[#{name}]"
    @template.labeled_fields_for(name, *args, &block)
  end

  def required_icon
    # "&nbsp;" + @template.tag(:span, :class=>'ss_sprite ss_star')
    @template.content_tag(:span, '*', :class=>'required')
  end

  def optional_tag
    #@template.content_tag(:span, "(optional)", :class=>'optional')
  end

end