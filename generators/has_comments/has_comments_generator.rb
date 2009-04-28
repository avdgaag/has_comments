class HasCommentsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'akismet.yml', 'config/akismet.yml'
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => 'create_comments'
    end
  end
end