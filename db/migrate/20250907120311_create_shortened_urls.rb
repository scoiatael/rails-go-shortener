class CreateShortenedUrls < ActiveRecord::Migration[7.2]
  def change
    create_table :shortened_urls, id: :uuid do |t|
      t.string :target
      t.text :slug

      t.timestamps
    end
    add_index :shortened_urls, :target
    add_index :shortened_urls, :slug
  end
end
