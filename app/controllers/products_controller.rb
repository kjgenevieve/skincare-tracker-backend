class ProductsController < ApplicationController
    def index
        if params[:limit]
            # puts "=================================="
            # puts "params are working!"
            # puts "=================================="
            @products = Product.limit(params[:limit])
        else
            @products = Product.all
            # puts "=================================="
            # puts ":( Not working :("
            # puts "=================================="
        end

        render json: @products
    end

    def show
        render json: Product.find(params[:id])
    end

    def search_brand_or_name
        results = []
        if params[:recent] == "true"
            # This possibility has been removed for now.

            # results = Product.all.sort_by(&:updated_at)
            # results = results.first(50)

            ## Both userInput (:search) && categories (:category) were passed via url
        elsif params[:search] != "undefined" && params[:search] != "" && params[:category] != "" && params[:category] != nil
            
            
        # This block was used for debugging!
            # if params[:category] == "undefined"
            #     puts "=================================="
            #     puts "UNDEFINED UNDEFINED UNDEFINED UNDEFINED"
            #     puts "=================================="
            # elsif params[:category] == nil
            #     puts "=================================="
            #     puts "NIL NIL NIL NIL"
            #     puts "=================================="
            # else
            #     puts "=================================="
            #     puts "<3 <3 <3 <3 <3 <3 <3 <3"
            #     puts "=================================="
            # end


            
            user_input_results = Product.search_by_brand_or_name(params[:search])

            categories_ary = params[:category].split(' ')

            if categories_ary.include?('Lip')
                categories_ary[categories_ary.index('Lip')] = 'Lip Care'
            end
            if categories_ary.include?("Eye")
                categories_ary[categories_ary.index('Eye')] = 'Eye Care'
            end

            if categories_ary.length == 1
                results = user_input_results.where(category: categories_ary)
            elsif categories_ary.length > 1
                i = 0
                while i < categories_ary.length
                    results = results + user_input_results.where(category: categories_ary[i])
                    i += 1
                end
            end

            results = results.sort_by(&:updated_at)
            results = results.first(75)
        
        elsif params[:search] != "undefined" && params[:search] != ""
            # Hits if only :search was passed and not :category
            results = Product.search_by_brand_or_name(params[:search])
            results = results.sort_by(&:updated_at)
            results = results.first(75)
        
        elsif params[:category]
            # Hits if only :category was passed and not :search
            categories_ary = params[:category].split(' ')

            if categories_ary.include?('Lip')
                categories_ary[categories_ary.index('Lip')] = 'Lip Care'
            end

            if categories_ary.include?("Eye")
                categories_ary[categories_ary.index('Eye')] = 'Eye Care'
            end

            if categories_ary.length == 1
                results = Product.all.where(category: categories_ary)
            elsif categories_ary.length > 1
                i = 0
                while i < categories_ary.length
                    results = results + Product.all.where(category: categories_ary[i])
                    i += 1
                end
            end

            results = results.sort_by(&:updated_at)
            results = results.first(75)
        else
            # This should no longer be needed, but it's here for debugging just in case. Clean up after finished messing with this component.
            # puts "=================================="
            # puts "Search and category params are both empty."
            # puts "=================================="
        end
        
        render json: results
    end
end
