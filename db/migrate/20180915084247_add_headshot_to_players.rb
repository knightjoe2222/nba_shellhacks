class AddHeadshotToPlayers < ActiveRecord::Migration[5.1]
  def change
    add_column :players, :headshot, :string
  end
end
