class HasCommentsGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.file 'akismet.yml', 'config/akismet.yml'

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => 'create_comments'
      end
    end
  end
end
