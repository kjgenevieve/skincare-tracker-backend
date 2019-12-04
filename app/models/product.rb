class Product < ApplicationRecord
    include PgSearch::Model
    pg_search_scope :search_by_brand_or_name,
        :against => [:brand, :name],
        using: {
            tsearch: {dictionary: "english"},
            dmetaphone: {dictionary: "english"},
            trigram: {
                threshold: 0.3
              }
          }

    has_many :user_products
    has_many :users, through: :user_products
    has_many :product_ingredients
    has_many :ingredients, through: :product_ingredients    

end
