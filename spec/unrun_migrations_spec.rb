require "spec_helper"

RSpec.describe PgHaMigrations::UnrunMigrations do
  describe "self.unrun_migrations", :test_isolation_strategy => :truncation do
    it "returns migrations that have not been run against the database" do
      migration = Class.new(ActiveRecord::Migration::Current) do
        def name
          "240_00"
        end
        def version
          123
        end
        def up
          safe_create_table :foos1 do |t|
            t.timestamps :null => false
            t.text :text_column
          end
          safe_create_table :foos2 do |t|
            t.timestamps :null => false
            t.text :text_column
          end
        end
      end

      migration.version = 24000
      migration.name = "240_00"

      migration.suppress_messages do
        ActiveRecord::Migrator.new(:up, [migration]).migrate
      end

      expect(PgHaMigrations::UnrunMigrations).to receive(:_migration_files).with("_oob").and_return(
        [
          "db/migrate_oob/924201_release_9242_01.rb",
          "db/migrate_oob/24000_release_240_00.rb",
        ]
      )

      unrun_migrations = PgHaMigrations::UnrunMigrations.unrun_migrations("_oob")

      expect(unrun_migrations).to include({:version => "924201"})
      expect(unrun_migrations).to_not include({:version => "24000"})
    end
  end
end