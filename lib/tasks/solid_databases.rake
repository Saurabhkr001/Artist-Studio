namespace :solid do
  desc "Prepare Solid Cache, Queue, and Cable databases"
  task prepare_databases: :environment do
    databases = {
      cache: "db/cache_schema.rb",
      queue: "db/queue_schema.rb",
      cable: "db/cable_schema.rb"
    }

    databases.each do |name, schema|
      puts "==> Preparing #{name} database..."

      config = ActiveRecord::Base.configurations.configs_for(
        env_name: Rails.env,
        name: name
      )

      db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
        Rails.env,
        name,
        config.configuration_hash
      )

      ActiveRecord::Tasks::DatabaseTasks.load_schema(
        db_config,
        :ruby,
        schema
      )

      puts "==> #{name} database ready."
    end
  end
end
