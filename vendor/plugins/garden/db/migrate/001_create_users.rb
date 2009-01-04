class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column "fullname",   :string,   :limit => 50
      t.column "wikilogin",  :string,   :limit => 50
      t.column "last_login", :datetime
    end
  end

  def self.down
    drop_table :users
  end
end
