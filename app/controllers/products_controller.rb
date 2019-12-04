class ProductsController < ApplicationController
    def index
        if params[:limit]
            puts "=================================="
            puts "params are working!"
            puts "=================================="
            @products = Product.limit(params[:limit])
        else
            @products = Product.all
            puts "=================================="
            puts ":( Not working :("
            puts "=================================="
        end

        render json: @products
    end

    # def index
    #     @filterrific = initialize_filterrific(
    #       Product,
    #       params[:filterrific]
    #     ) or return
    #     @products = @filterrific.find.page(params[:page])
     
    #     respond_to do |format|
    #       format.html
    #       format.js
    #     end
    #   end


    def show
        render json: Product.find(params[:id])
    end

    def search_brand_or_name
        results = []
        if params
            puts "=================================="
            puts params
            puts "=================================="
            if params[:recent] == "true"
                results = Product.all.sort_by(&:updated_at)
                results = results.first(50)
            elsif params[:search]
                results = Product.search_by_brand_or_name(params[:search])
                results = results.sort_by(&:updated_at)
                results = results.first(75)        
            end
        end
        
        render json: results
    end
end
