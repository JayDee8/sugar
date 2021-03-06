# encoding: utf-8

module LayoutHelper

  def add_body_class(*class_names)
    @body_classes ||= []
    @body_classes += [class_names].flatten # Should also work with arrays
  end

  def body_classes
    @body_classes ||= []
    @body_classes << 'with_sidebar' if content_for?(:sidebar) && !@body_classes.include?('with_sidebar')
    @body_classes.uniq.join(' ')
  end

  def frontend_configuration
    {
      debug:              (Rails.env == "development"),
      emoticons:          enabled_emoticons,
      flickrApi:          Sugar.config.flickr_api,
      facebookAppId:      Sugar.config.facebook_app_id,
      amazonAssociatesId: Sugar.config.amazon_associates_id,
      uploads:            Sugar.aws_s3?,
      currentUser:        current_user.try(&:as_json),
      preferredFormat:    current_user.try(&:preferred_format)
    }
  end

  def search_mode_options
    options = [['in discussions', search_path], ['in posts', search_posts_path]]
    options << ["in this #{@exchange.type.downcase}", polymorphic_path([:search_posts, @exchange])] if @exchange && @exchange.id
    options
  end

  def header_tab(name, url, options={})
    options[:section] ||= name.downcase.to_sym
    options[:id]      ||= "#{options[:section]}_link"
    options[:class]   ||= []
    options[:class]   = [options[:class]] unless options[:class].kind_of?(Array)

    classes = [options[:section].to_s] + options[:class]
    classes << 'current' if @section == options[:section]

    content_tag(
      :li,
      link_to(name, url, id: options[:id]),
      class: classes
    )
  end

  private

  def enabled_emoticons
    Sugar.config.emoticons.split(/\s+/).map do |name|
      if emoji = Emoji.find_by_alias(name)
        { name: name, image: image_path("emoji/#{emoji.image_filename}") }
      end
    end.compact
  end

end
