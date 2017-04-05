require 'redmine/plugin'

module RedminePluginPatch
  extend ActiveSupport::Concern

  included do
    prepend PrependModule
  end

  module PrependModule
    def mirror_assets
      source = assets_directory
      destination = public_directory
      return unless File.directory?(source)

      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs

      unless source_files.empty?
        base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ''))
        begin
          FileUtils.mkdir_p(base_target_dir)
        rescue Exception => e
          raise "Could not create directory #{base_target_dir}: " + e.message
        end
      end

      source_dirs.each do |dir|
        # strip down these paths so we have simple, relative paths we can
        # add to the destination
        target_dir = File.join(destination, dir.gsub(source, ''))
        begin
          FileUtils.mkdir_p(target_dir)
        rescue Exception => e
          raise "Could not create directory #{target_dir}: " + e.message
        end
      end

      # data prepared to write into plugin_manifest.json
      plugin_name = self.id.to_s
      data = {}
      data["#{plugin_name}"] = {}
      data["#{plugin_name}"]['javascripts'] = {}
      data["#{plugin_name}"]['stylesheets'] = {}
      # data["#{plugin_name}"]['images'] = {}


      source_files.each do |file|
        begin
          target = File.join(destination, file.gsub(source, ''))

          # data prepared to write into plugin_manifest.json
          filename = File.split(file).last
          file_extname = File.extname(filename)
          file_basename = File.basename(filename, file_extname)

          case file_extname
            when '.js'
              # computing fingerprint
              digest = Digest::MD5.hexdigest(File.read(file))
              # adding fingerprint
              target.insert(target.rindex('.'), "-#{digest}")

              data["#{plugin_name}"]['javascripts'][file_basename] = {
                  'digest' => digest,
                  'digest_filename' => "#{File.split(target).last}"
              }
            when '.css'
              # computing fingerprint
              digest = Digest::MD5.hexdigest(File.read(file))
              # adding fingerprint
              target.insert(target.rindex('.'), "-#{digest}")

              data["#{plugin_name}"]['stylesheets'][file_basename] = {
                  'digest' => digest,
                  'digest_filename' => "#{File.split(target).last}"
              }
            else
              # data["#{plugin_name}"]['images'][file_basename] = {
              #     'digest' => digest,
              #     'digest_filename' => "#{File.split(target).last}"
              # }
          end

          unless File.exist?(target) && FileUtils.identical?(file, target)
            FileUtils.cp(file, target)
          end
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: " + e.message
        end
      end

      # write data into plugin_manifest.json
      begin
        basename = "#{plugin_name}_manifest.json"
        manifest_path = File.join(destination, basename)
        File.open(manifest_path, 'wb+') do |f|
          f.write data.to_json
        end
      rescue Exception => e
        raise "Could not write data to  #{manifest_path} : " + e.message
      end

    end
  end

end

Redmine::Plugin.send(:include, RedminePluginPatch)