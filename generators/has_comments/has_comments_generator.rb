class HasCommentsGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      # m.directory "lib"
      # m.template 'README', "README"

      # Install jQuery plugin and styles for managing controls
      m.file 'jquery.manage-comments.js', "public/javascripts/#{file_name}.css"
      m.file 'manage-comments.css', "public/stylesheets/#{file_name}.css"

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
            :migration_name => "Create#{class_name.pluralize.gsub(/::/, ‘‘)}"
          }, :migration_file_name => "create_#{file_path.gsub(/\//, ‘_’).pluralize}"
      end
    end
  end
end
