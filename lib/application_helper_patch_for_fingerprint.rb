module ApplicationHelperPatchForFingerprint
  extend ActiveSupport::Concern

  included do
    prepend PrependModule
  end

  module PrependModule
    def digest_path(plugin, source, type)
      data = JSON.parse(File.read(File.join(Rails.root, "/public/plugin_assets/#{plugin}/#{plugin}_manifest.json")),
                        create_additions: false)

      if source.match(/\//).present?
        sources = source.split('/')
        source = sources.pop
      end
      source_extname = File.extname(source)
      if source_extname.match(/\.(js|css|png|gif|jpe?g)/).present?
        source = File.basename(source, source_extname)
      end

      case type
        when 'javascripts'
          digest_name = data["#{plugin}"]['javascripts']["#{source}"]['digest_filename']
        when 'stylesheets'
          digest_name = data["#{plugin}"]['stylesheets']["#{source}"]['digest_filename']
        # when 'images'
        #   digest_name = data["#{plugin}"]['images']["#{source}"]['digest_filename']
      end

      if sources.present?
        "/plugin_assets/#{plugin}/#{type}/#{sources.join('/')}/#{digest_name}"
      else
        "/plugin_assets/#{plugin}/#{type}/#{digest_name}"
      end
    end

    # Overrides Redmine' stylesheet_link_tag
    #
    def stylesheet_link_tag(*sources)
      options = sources.last.is_a?(Hash) ? sources.pop : {}
      plugin = options.delete(:plugin)
      sources = sources.map do |source|
        if plugin
          digest_path(plugin, source, 'stylesheets')
        elsif current_theme && current_theme.stylesheets.include?(source)
          current_theme.stylesheet_path(source)
        else
          source
        end
      end
      super *sources, options
    end

    # Overrides Redmine' image_tag
    #
    # def image_tag(source, options={})
    #   if plugin = options.delete(:plugin)
    #     source = digest_path(plugin, source, 'images')
    #   elsif current_theme && current_theme.images.include?(source)
    #     source = current_theme.image_path(source)
    #   end
    #   super source, options
    # end

    # Overrides Redmine' javascript_include_tag
    #
    def javascript_include_tag(*sources)
      options = sources.last.is_a?(Hash) ? sources.pop : {}
      if plugin = options.delete(:plugin)
        sources = sources.map do |source|
          if plugin
            digest_path(plugin, source, 'javascripts')
          else
            source
          end
        end
      end
      super *sources, options
    end
  end
end

ApplicationHelper.send(:include, ApplicationHelperPatchForFingerprint)