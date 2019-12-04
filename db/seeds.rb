require 'mechanize'
require 'pry'

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# User.destroy_all
# Product.destroy_all
# UserProduct.destroy_all
# Ingredient.destroy_all
# ProductIngredient.destroy_all

# u1 = User.create
# u1.name = "Genevieve"
# u1.save


# @scraped_products = []
@scraped_product = []

def get_basic_info(url, product_obj)
    mechanize = Mechanize.new
    
    begin
        page = mechanize.get(url)
    rescue Mechanize::ResponseCodeError => exception
        if exception
            puts ResponseCodeError
            return exception
        end
    end

    product_obj["name"] = page.search('h1').text
    product_obj["brand"] = page.search('h2').text
    
    get_image(page, product_obj)
end

def get_image(page, product_obj)
    scraped_image = page.search("div[id='main-product'] img").first['src']
    
    if scraped_image.include?("product-img-placeholder")
        product_obj["img_url"] = "/Users/genevieve/Development/mod_5/skincare-tracker/frontend/src/assets/product_image_placeholder.svg"
    else
        product_obj["img_url"] = scraped_image
    end
    product_obj["img_url"]

    get_category(page, product_obj)
end

def get_category(page, product_obj)
    scraped_category = ""
    categories = page.search('.category-badge').text.downcase
    if categories.include? "cleansers"
        scraped_category = "Cleanser"
    elsif categories.include? "moisturizers"
        scraped_category = "Moisturizer"
    elsif categories.include? "masks"
        scraped_category = "Mask"
    elsif categories.include? "sunscreen"
        scraped_category = "Sunscreen"
    elsif categories.include? "treatments"
        scraped_category = "Treatment"
    elsif categories.include? "toners"
        scraped_category = "Toner"
    elsif categories.include? "lip care"
        scraped_category = "Lip Care"
    elsif categories.include? "eye care"
        scraped_category = "Eye Care"
    elsif categories.include? "mists"
        scraped_category = "Mist"
    else
        scraped_category = "Misc"
    end

    product_obj["category"] = scraped_category
    get_ingredients(page, product_obj)
end

def get_ingredients(page, product_obj)
    ingredients_arry = []
    table = page.search('tr')
    table.each do |thingy|
        if thingy.search('td')[2].class != NilClass
            ingredient = thingy.search('td')[2].children.first.text.strip.gsub(/\s+/, " ") 
            if thingy.search('td')[3].text.include?("Comedogenic Rating")
                como_rating = thingy.search('td')[3].children.search('div.badge-label').last.text.delete("Comedogenic Rating (").delete(")")
                ingredients_arry << [ingredient, como_rating]
            else
                ingredients_arry << [ingredient, nil]
            end
        end
    end

    product_obj["ingredients"] = ingredients_arry

    get_sunscreen(product_obj)
end

def get_sunscreen(product_obj)
    scraped_pa = nil
    scraped_spf = nil
    
    product = product_obj["name"]
    
    if product.downcase.include?("spf") || product.include?("pa+")
        scraped_spf = product.downcase.gsub(/\s+/, "")[/spf../]
        if scraped_spf.class != NilClass
            scraped_spf.slice!("spf")
        

            if product.include?(scraped_spf + "+")
                scraped_spf = scraped_spf + "+"
            end
            if product.include?("100")
                scraped_spf = "100"
            end
            scraped_spf
        end

        # Get PA rating        
        if product.downcase.include?("pa++++")
            scraped_pa = "++++"
        elsif product.downcase.include?("pa+++")
            scraped_pa = "+++"
        elsif product.downcase.include?("pa++")
            scraped_pa = "++"
        elsif product.downcase.include?("pa+")
            scraped_pa = "+"
        else
            scraped_pa = nil
        end
        scraped_pa
    end

    product_obj["spf"] = scraped_spf
    product_obj["pa"] = scraped_pa

    add_to_array(product_obj)
end

def add_to_array(product_obj)
    @scraped_product = product_obj
end

def add_to_db(scraped_product)
    # puts "SCRAPED PRODUCTS ARRAY!!!!!!"
    # puts scraped_products_array
    counter = 1
    # scraped_products_array.each do |product|
    product = scraped_product
        # if Product.all.count > 0
            # if Product.find_by(name: product["name"]) != nil
            #     product = product
            # end
        # else
            
            p1 = Product.create
            # temp = product["brand"]
            p1.brand = product["brand"],
            p1.name = product["name"],
            p1.category = product["category"],
            p1.img_url = product["img_url"],
            p1.sunscreen_type = product["sunscreen_type"],
            p1.spf = product["spf"],
            p1.pa = product["pa"],
            
            ## the brand attribute gets overwritten with a string of all the attributes; this fixes it
            p1.brand = nil,
            p1.brand = product["brand"],
            p1.save
            
            
            product["ingredients"].each do |ingredient|
                i1 = Ingredient.find_or_create_by(name: ingredient[0])
                i1["como_rating"] = ingredient[1]
                i1.save

                pi1 = ProductIngredient.create
                pi1["product_id"] = p1.id
                pi1["ingredient_id"] = i1.id
                pi1.save
            end

        # # end
        # puts "============================"
        # puts "#{counter} added to db"
        # puts "============================"
        # counter += 1
    
end

## Links ##

links = [
    "https://www.skincarisma.com/products/alverde-naturkosmetik/gesichtswasser-clear-gesichtstonic-heilerde/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/getonte-tagescreme-perfekter-teint-color-correction-porzellanblume/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/getonter-sonnenbalm-lsf-20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/highlighter/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/hydro-augen-roll-on-mit-hyaluron/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/hydro-nature-feuchtigkeitscreme-bio-aloe-vera/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/klarende-maske-beauty-fruity-bio-limette-bio-apfel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/korperbutter-macadamianuss-karitebutter/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/korperol-cellulite-bio-zitrone-bio-rosmarin/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/make-up-entfernerol/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/make-up-foundation-sensitive/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/make-up-primer-hautbild-verfeinerer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/make-up-primer-professional-anti-shine-primer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/med-pflegecreme-heilquellenwasser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/med-pflegelotion-heilquellenwasser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/men-hydro-nature-augen-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/mineral-make-up/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/mineral-puder-natural-02/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/nachtcreme-wildrose/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/naturschon-augencreme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/naturschon-gesichtscreme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/naturschon-reinigungsmilch/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/overnight-mask-silber/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/peeling-freude-mit-bachbluten/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/perfect-cover-foundation-concealer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/perfekter-teint-schonheitsessenz/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/primer-oil-drops/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/q10-karotten-gesichtsol/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/q10-tagescreme-bio-gojibeere/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/reinigungsmilch-perfekter-teint-gel-to-milk-reinigungsgel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/reinigungsschaum-beauty-fruity-3in1-bio-limette-bio-apfel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/reinigungsschaum-beauty-fruity-3in1-limette-apfel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/reinigungsschaum-sensitiv-3in1/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/serum-q10-bio-gojibeere/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/serum-zell-aktiv-blauer-hibiskus/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/shampoo-ultra-sensitive/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/softcreme-bio-aloe-vera-and-bio-jojoba/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/sonnencreme-sensitiv-lsf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagescreme-aqua-24h-hyaluron-hydro-cremegel-meeresalge/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagescreme-bio-wildrose/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagespflege-beauty-fruity-mattierende-pflegecreme-bio-limette-bio-apfel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagespflege-vertrauen/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagespflege-vital-lupinen-peptide/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagespflege-vital-mit-olkomplex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/tagespflege-zell-aktiv-blauer-hibiskus/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alverde-naturkosmetik/waschcreme-clear-heilerde/ingredient_list#info-section",
    "https://www.skincarisma.com/products/always-be-pure/forest-therapy-ultra-calming-cream-b9e65ea3-8f46-4fde-b574-8bc68dafbda5/ingredient_list#info-section",
    "https://www.skincarisma.com/products/always-be-pure/forest-therapy-ultra-calming-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/always21/aloe-vera-soothing-gel-99/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alya-skin/australian-native-berries-moisturiser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alya-skin/pink-clay-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alya-skin/pomegranate-facial-exfoliator/ingredient_list#info-section",
    "https://www.skincarisma.com/products/alyria/oil-free-hydrating-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/am-taiwan/pigyhead-series-beitou-hot-spring-water-moisturize-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amaira/advanced-scar-vanishing-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amaki/grapefruit-deep-cleansing-oil-makeup-remover/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amaki/japanese-tsubaki-anti-aging-face-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amaki/rose-water-hydrating-mist-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amalia-skincare/refreshing-gel-cleanser-5cf9748d-fa95-4de8-9404-29ef3648db21/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amanda-lacey/camellia-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amanda-lacey/cleansing-pomade/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amanda-lacey/illuminating-eye-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amanda-lacey/miracle-tonic/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amanda-lacey/oils-of-provence/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amara-organics/advanced-age-defying-moisturizer-with-fruit-stem-cells-resveratrol/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amara-organics/aloe-vera-gel-cold-pressed-aloe/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amareta/bright-side-balancing-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amavara/spf-50-earthwell-zinc-technology-tinted-mineral-sunscreen/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amazonia/jasmine-honey-cleansing-milk/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ambi/complexion-cleansing-bar-soap/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ambi/creamy-oil-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ambi/even-clear-exfoliating-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ambi/even-clear-foaming-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ambi/facial-moisturizer-47eac079-b566-4c54-849a-d4aa37a4fca7/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ambi/fade-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ame-pure/cleansing-gel-09f4d188-e8ed-4627-9a73-24e4a140136e/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ame-pure/duo-multiplex-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ameliorate/transforming-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/american-crew/24-hour-deodorant-body-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/american-crew/daily-moisturizing-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/american-crew/daily-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/american-crew/defining-paste/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amicell/aloe-vera-moisture-soothing-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amie/spring-deep-cleansing-face-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amihan-organics/sunbug/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amika/nourishing-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/counter-clockwise-under-eye-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/paranormal-efx-anti-aging-super-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/perfect-reflection-anti-aging-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/photolagen-agf/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/quadrafill-targeted-deep-wrinkle-filler-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/really-really-clean-moisturizing-facial-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/simply-one-10-in-1-skin-perfecting-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/spot-light-skin-brightener-and-corrector/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/therapeutic-facial-repair/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aminogenesis/tripeptinon-facial-lift-capsules/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amlactin/cerapeutic-alpha-hydroxy-ceramide-therapy-restoring-body-lotion-fragrance-free/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amlactin/foot-cream-therapy/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amlactin/moisturizing-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amlactin/rapid-relief/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amlactin/ultra-hydrating-body-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amomati-medicinals/longevity-potion-face-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/botanical-radiance-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/green-tea-seed-treatment-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/intensive-vitalizing-eye-essence/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-intensive-vitalizing-eye-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-lip-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-refreshing-hydra-gel-oil-free/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-rejuvenating-creme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-rejuvenating-eye-treatment-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-rejuvenating-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-skin-energy-hydration-delivery-system/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/moisture-bound-skin-energy-hydration-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/sun-protection-cushion-spf50-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/the-essential-creme-fluid/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/time-response-eye-renewal-creme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/treatment-cleansing-foam/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/treatment-cleansing-oil-face-eyes/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/treatment-cleansing-tissue/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/treatment-enzyme-peel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/treatment-enzyme-peel-cleansing-powder/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/vintage-single-extract-essence/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amorepacific/youth-revolution-radiance-creme-and-masque/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ample-n/acne-shot-ampoule/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ample-n/ceramide-shot-ampoule/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ample-n/ceramide-shot-barrier-sun-care-spf-50-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ample-n/hyaluron-shot-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ample-n/peptide-shot/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ampm/skin-ecological-indoor-defense-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ampm/total-brightening-renewal-treatment-mandelic-acid-5/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ampm/wake-up-skin-smooth-washing-powder/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ampro/pro-styl-neutra-foam-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amway/artistry-hydra-v-nourishing-gel-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/amway/complexion-bar/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/brow-enhancing-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/brow-powder-duo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/brow-wiz/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/clear-brow-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/dewy-set-setting-spray/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/dipbrow-pomade/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/duo-eyebrow-powder-auburn/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anastasia-of-beverly-hills/sun-dipped-glow-kit/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-absolute-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-beautiful-day-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-cc-color-correct-sheer-tan-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-cleansing-foam/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-daily-shade-facial-lotion-with-spf-18/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-eye-revive-contour-gel-sensitive/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-floral-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-heavenly-night-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-moroccan-beauty-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/1000-roses-pearl-exfoliator/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/acai-kombucha-oil-free-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/acai-white-tea-oil-free-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/aloe-mint-cooling-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/aloe-mint-cooling-shower-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/apricot-probiotic-cleansing-milk/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/argan-mint-lip-remedy/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/argan-omega-natural-glow-3-in-1-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/argan-stem-cell-bb-benefit-balm-un-tinted-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/argan-stem-cell-recovery-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/avo-cocoa-skin-food-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/bioactive-8-berry-fruit-enzyme-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/blemish-vanishing-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/blossom-leaf-toning-refresher/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/blossom-leaf-toning-refresher-age-defying/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/brightening-clementine-c-illuminating-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/brightening-meyer-lemon-creamy-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/cannacell-sun-buddy-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/chia-omega-radiant-skin-polish/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/citrus-kombucha-cleansing-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/clear-skin-kombucha-enzyme-exfoliating-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/clementine-c-illuminating-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/clementine-ginger-energizing-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/clementine-ginger-energizing-shower-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/coconut-water-eye-lift-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/coconut-water-firming-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/diy-booster-spf-30-facial-serum-unscented-with-resveratrol-q10-youthful-vitality/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/exotic-marula-oil-deep-conditioning-hair-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/fruit-stem-cell-revitalize-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/hyaluronic-dmae-lift-firm-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/instant-hydration-hydro-serum-facial-mask-1000-roses-soothing-fiber-sheet-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/instant-pure-pore-hydro-serum-facial-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/kombucha-enzyme-exfoliating-peel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/kukui-cocoa-body-butter/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/lash-plus-lid-make-up-remover-brightening/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/lavender-shea-body-butter/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/lemon-sugar-facial-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/luminous-eye-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/meyer-lemon-creamy-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/oil-control-beauty-balm-un-tinted-with-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/perfecting-bb-beauty-balm-natural-tint-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/probiotic-c-renewal-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/pumpkin-honey-glycolic-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/purple-carrot-c-luminous-night-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/reservatrol-q10-night-repair-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/revitalizing-lash-lid-make-up-remover/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/super-goji-peptide-perfecting-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/turmeric-c-enlighten-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/ultra-sheer-daily-defense-facial-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/ultra-sheer-daily-defense-facial-lotion-with-spf-18/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/vitamin-c-bb-beauty-balm-sheer-tint-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/willow-bark-pure-pore-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andalou-naturals/willow-bark-pure-pore-toner-clear-skin/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andes-nature/cosmetic-snail-extract-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andlab/take-out-spa-healthy-juice-mask-my-bright-bottle/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andlab/take-out-spa-healthy-juice-mask-my-soothing-bottle/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andlab/take-out-spa-healthy-juice-mask-my-volume-bottle/ingredient_list#info-section",
    "https://www.skincarisma.com/products/andlab/xylitol-mild-sun-cushion-spf50-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-bb-based-beauty-booster/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-uv-liquid-n/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-uv-pact-n/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-uv-sunscreen-mild-milk-for-sensitive-skin-spf-50-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-uv-sunscreen-mild-milk-spf50/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-uv-sunscreen-milk-spf50/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anessa/perfect-uv-sunscreen-skincare-milk-spf-50-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anfisa/regenerating-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angela-caglia/detox-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angela-caglia/dream-exfoliant-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angela-caglia/facial-in-a-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angela-caglia/luxurious-face-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angela-caglia/power-cleansing-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angela-caglia/souffle-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/angfa/scalp-d-beaute-pure-free-eyelash-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anglamark/sun-face-spf30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anglamark/sun-lotion-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anjou/dead-sea-mud-mask-aa3d1ee2-7490-4098-a9d2-7854b8841fd0/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anna-lotan/new-age-control-purifying-liquid-soap/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anna-lucia-organic/face-mist-rosewater-x-witch-hazel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annagaspi/vitamin-c30-marinestar-ampoule/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anne-semonin/brightening-cream-spf15/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anne-semonin/express-radiance-ice-cubes/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anne-semonin/gel-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anne-semonin/oligo-protect-cream-spf30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anne-semonin/precious-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anne-semonin/super-active-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annemarie-borlind/cooling-sun-spray-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annemarie-borlind/mild-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annemarie-borlind/purifying-care-clarifying-cleansing-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/arbutin-hyaluronic-acid-brighting-jelly-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/bubble-tea-mask-black-tea/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/bubble-tea-mask-green-tea/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/bubble-tea-mask-mango/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/bubble-tea-mask-strawberry/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/calendula-softening-jelly-spray/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/ginkgo-seaweed-anti-wrinkle-eye-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/honey-deep-moisturizing-jelly-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/hyaluronic-acid-seaweed-hydrating-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/lavender-chamomile-soothing-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/secret-garden-black-rose-devil-s-moisturizing-secret-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annie-s-way/tea-tree-burdock-anti-acne-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annona/vitamin-c-moisturizing-cream-a9e51cc1-03e2-4007-ba0b-b80a76df4551/ingredient_list#info-section",
    "https://www.skincarisma.com/products/annona/vitamin-c-serum-790d0bc0-0796-44cf-aeb8-86fe45fba8d7/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anora/fortifying-active-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anskin/age-defy-line-smoothing-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anskin/eco-cup-modeling-mask-shongga-moisturizing-soothing/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antabax/antibacterial-shower-cream-sensitive/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/advanced-formula-lip-balm-spf-25-mint-and-white-tea/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/advanced-formula-mint-white-tea-lip-balm-spf-25/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/after-shave-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/alcohol-free-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/algae-facial-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/all-purpose-facial-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/astringent-toner-pads/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/body-cleansing-gel-eucalyptus-mint/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/certified-organic-baked-foundation/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/continuous-moisture-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/facial-moisturizer-spf-15/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/facial-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/glycerin-cleansing-bar/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/glycerin-hand-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/glycolic-exfoliating-resurfacing-wipes/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/glycolic-facial-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/instant-fix-oil-control/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/invigorating-rush-hair-body-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/mud-scrub-exfoliating-bar/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/oil-free-facial-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/oil-free-facial-lotion-spf-15/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/pre-shave-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/sea-salt-body-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/self-tanner-with-anti-aging-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/shave-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/shave-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anthony/vitamin-c-facial-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/apostle-skin-brightening-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/aura-manuka-honey-treatment-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/avocado-pear-nourishing-night-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/divine-face-oil-avocado-oil-rosehip/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/grace-gentle-cream-clenser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/hallelujah-lime-patchouli-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/hosanna-h2o-intensive-skin-plumping-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/joyous-protein-rich-night-replenish-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/juliet-brightening-face-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/kiwi-seed-oil-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/reincarnation-pure-facial-exfoliator/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/rejoice-light-facial-day-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antipodes/vanilla-pod-hydrating-day-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/cream-supreme-facial-moisturiser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/forest-dew-skin-tonic/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/luminous-light-polishing-powder/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/mask-supreme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/natural-glow-cleansing-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/pure-therapy-facial-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonia-burrell/radiant-light-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonym/certified-organic-eyeshadow-quattro/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonym/certified-organic-highligher/ingredient_list#info-section",
    "https://www.skincarisma.com/products/antonym/skin-esteem-organic-liquid-foundation/ingredient_list#info-section",
    "https://www.skincarisma.com/products/anubis/new-even-tonifying-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aok/glanzlos-schon-tagescreme-mit-weissem-tee/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aok/peeling-seesand-mit-weissem-tee/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aok/waschgel-mit-weissem-tee/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apaisac-biorga/soothing-anti-redness-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aphogee/keratin-green-tea-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aphorism-skincare/bright-as-day-radiance-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aphorism-skincare/clear-sailing-balancing-facial-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aphorism-skincare/night-is-young/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apicare/manuka-therapy-30-honey-creme-umf15/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apidermin-expert/ser-active-restructurant-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/5-action-eye-serum-intensive-care-eye-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/anti-wrinkle-light-texture-face-cream-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/aqua-beelicious-booster/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/aqua-vita-advanced-moisture-revitalizing-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/aqua-vita-intense-moisturizing-and-revitalizing-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/bee-radiant-age-defense-illuminating-cream-light-texture/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/bee-radiant-age-defense-illuminating-day-cream-spf30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/bee-radiant-age-defense-illuminating-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/bee-radiant-age-defense-illuminating-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/cleansing-foam-face-eyes-with-olive-lavender/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/cleansing-gel-for-oily-combination-skin/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/cleansing-gel-with-citrus-propolis/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/gentle-daily-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/intimate-care-gentle-cleansing-gel-for-the-intimate-area/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/moisturizing-cream-gel-with-cedar-propolis/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/moisturizing-face-mask-with-sea-lavender/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/oil-balance-light-texture-face-cream-spf-30-high-protection/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/oil-balance-light-texture-tinted-face-cream-spf-30-high-protection/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/queen-bee-holistic-age-defense-day-cream-spf20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/queen-bee-holistic-age-defense-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/queen-bee-holistic-age-defense-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/wine-elixir-wrinkle-firmness-lift-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apivita/wine-elixir-wrinkle-lift-eye-lip-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apollo/sebo-de-macho/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apolosophy/face-hydrating-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apotek-1/dermica-sensitiv-solkrem-hoy-beskyttelse/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apoteket/aloe-vera-gel-fc61d1fd-46dc-4c5b-a9f0-14431d23abf1/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apoteket/aterfuktande-ansiktsgel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apoteket/djupintensiv-nattcreme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apothaka/comforting-cleansing-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apothecare-essentials/the-mender-hair-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apotheke/brightening-night-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apotheke/firming-toner-for-men/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apotheke/niacinamide-10/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apotheke/skin-doctor-for-men/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apotheke/spot-treatment-cdb356af-1a38-4199-a638-fa79956eb158/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-22/rose-energy-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/blue-mineral-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/calamine-solution-spot-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/honey-and-red-ginseng-sheet-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/madeca-solution-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-all-kill-cleansing-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-essence-shower-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-bb/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-cushion-black/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-cushion-spf50/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-cushion-white/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-fixing-foundation/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-sun-stick/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-snow-whitening-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/magic-stone-black/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/mermaid-hydrogel-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/mummy-mud-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/perfect-cover-magic-fit-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/perfect-magic-cover-proof-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/perfect-magic-dual-cover-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/perfect-magic-face-starter/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/perfect-magic-matte-starter/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/pinky-piggy-carbonated-pack/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/pinky-piggy-collagen-pack/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/real-calendula-deep-moisture-essence/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/real-calendula-foam-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/real-calendula-peeling-pad/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/rose-glam-moisture-cover-foundation/ingredient_list#info-section",
    "https://www.skincarisma.com/products/april-skin/signature-soap-original/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aprolis/crema-de-propoleo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apto-skincare/healing-mask-with-turmeric/ingredient_list#info-section",
    "https://www.skincarisma.com/products/apto-skincare/nourishing-mask-with-blue-spirulina/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aq-skin-solutions/eye-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqua-international/aqua-pore-luminous/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqua-series/bright-up-daily-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqua-series/purifying-cleansing-water/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqua-series/soothing-purifying-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquanil/cleanser-234bcfb1-5bce-40fc-83c8-06bcbe9395c8/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquaphor/baby-wash-shampoo-natural-chamomile-essence-fragrance-free/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquaphor/lip-repair-protect-broad-spectrum-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquaphor/ointment-body-spray/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquareveal/smooth-talker-water-peel-for-lips/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquation/daily-moisturizing-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquation/gentle-moisturizing-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquation/moisturizing-cream-powered-by-hydro-balance/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aquis/prime-water-defense-pre-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqulabo/mask-boosting-jelly-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqulabo/oh-very-bright-mask-sheet/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aqutop/all-in-one-cacao-cleansing-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/abc-baby-care-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/abc-body-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/abc-hair-body-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/abc-herbal-diaper-rash-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/abc-sunscreen-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/aromassentials-awaken-bath-and-shower-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/aromassentials-awaken-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/aromassentials-awaken-massage-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/aromassentials-awaken-sea-salt-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/before-sun-damage-control-water-resistant-sunscreen-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/calm-gentle-daily-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/calm-gentle-daily-moisturizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/calm-soothing-eye-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/calm-soothing-facial-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/cc-cream-fair-7795/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/clear-advantage-acne-spot-treatment-salicylic-acid-2/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/clear-advantage-clarifying-lotion-acne-medication-salicylic-acid-1/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/clear-advantage-clarifying-toner-acne-medication/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/eye-makeup-remover-2ae7ec83-9ca7-47b6-984f-ee7794db7501/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-deep-cleansing-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-exfoliating-new-cell-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-hydrating-cleanser-freshener/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-hydrating-eye-creme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-intense-hydration-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-moisturizing-night-creme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-nurturing-day-lotion-with-spf-20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-purifying-cleanser-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/fc5-skin-conditioning-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/glow-with-it-after-sun-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/intelligence-genius/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/intelligence-rejuvenating-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/lip-saver-spf-30/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/prolief-natural-balancing-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-age-defying-neck-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-cellular-renewal-masque/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-corrective-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-for-men-exfoliating-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-for-men-facial-moisturizer-spf-20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-for-men-post-shave-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-for-men-shave-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-instant-lift-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-intensive-renewal-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-night-repair-creme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-regenerating-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-restorative-cream-spf-15-sunscreen/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-restorative-day-creme-spf-20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/re9-advanced-smoothing-facial-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/revelage-age-spot-brightening-hand-therapy-broad-spectrum-spf-30-sunscreen/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/revelage-concentrated-age-spot-minimizer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/revelage-intensive-pro-brightening-night-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/seasource-detox-spa-detoxifying-rescue-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/shea-butter-hand-body-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arbonne/shea-butter-hand-body-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arche/pearl-cream-873f4256-e920-4849-9b5e-23726da7115e/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/am-blemish-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/booster-defense-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/brightening-drops/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/brightening-gommage/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/chamomile-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/cranberry-gommage/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/cranberry-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/eye-dew-ef61932d-b778-4391-b105-fb6cf5701982/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/eye-serum-4a6e9424-68e9-4742-b178-6cca0bfe2b20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/g-factor-skin-renewal-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/gentle-solution/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/golden-grain-gommage/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/hydrating-serum-0b4aba8f-8266-4afe-b568-711fe0ce76a6/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/instant-magic-reversal-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/magic-dry-ice/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/magic-white-ice/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/mandarin-brightening-peel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/night-breeze/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/night-worker/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/overnight-cellular-repair-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/papaya-enzyme-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/peptide-eye-wrinkle-repair/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/peptide-hydrating-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/pm-blemish-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/raspberry-clarifying-pads/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/raspberry-resurfacing-peel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/reozone-spf-20/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/tabula-rasa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/tabula-rasa-pads/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/tea-tree-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/the-solution/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/the-solution-pads/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/triad-pads/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/vitamin-a-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/white-tea-purifying-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/wine-hydrating-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/wine-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/wrinkle-repair-gf-complex/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcona/youth-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arcova-korea/royal-jelly-sleeping-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ardell/attitude-adjustor-shade-fx-drops-golden-sheen/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argan-smooth/corrective-leave-in-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argan-smooth/epic-moisture-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argania/light/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argansouss-puur/argan-pure-zeep/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argansouss-puur/creme-arganolie/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argentum-plus/silver-msm-seb-derm-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argentum/l-etoile-infinie-face-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argentum/la-potion-infinie/ingredient_list#info-section",
    "https://www.skincarisma.com/products/argentum/le-savon-lune-hydration-bar/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ari-brands/retinol-repair-vitamin-c-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aria-starr-beauty/100-pure-organic-cold-pressed-rosehip-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aria-starr-beauty/dead-sea-mud-mask-2e2e6b71-a735-455d-927a-3dc6a3e3f76e/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/all-day-makeup-fixer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/aloe-no-wash-cleansing-water/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/baby-face-mist-collagen/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/fresh-power-essence-mask-sheet-honey/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/fresh-power-essence-mask-sheet-pearl/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/fresh-power-essence-pouch-pack/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/full-cover-bb/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/ginger-sugar-lip-care-stick/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/ginger-sugar-lip-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/ginger-sugar-overnight-lip-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/ginger-sugar-tint-lip-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/heart-in-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/jelly-bar/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/parasol-tone-up-sun-pact/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/pore-master-sebum-control-matte-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/pore-master-sebum-control-primer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/pore-master-sebum-control-stick/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/real-ampoule-brightener/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/real-ampoule-color-corrector/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/real-pure-peeling-booster/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/salon-esthe-mask-ceramide-sleeping-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/satin-pencil-lip-laquer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/teatree-solution-cica-focus-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aritaum/wonder-stay-stick-tint/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/7-days-vitamin-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/7days-mask-lemon/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/aloe-7-days-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/aqua-blast-balancing-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/aqua-blast-clearing-toner-ea9f3ac5-78e9-465f-a16e-86480cf2f7ff/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/aqua-blast-hydrating-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/berry-blast-brightening-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/berry-blast-keep-20-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/berry-vital-recharging-gel-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/brilliant-tone-up-egg-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/brilliant-tone-up-egg-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/erry-blast-boosting-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/kale-grapefruit-juice-cleanse-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/raspberry-lentil-juice-cleanse-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/spa-water-24h-moisturizing-refreshing-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/spa-water-24hr-moisturizing-refreshing-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/spearmint-green-apple-juice-cleanse-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/stress-relieving-purefull-cleansing-foam/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/stress-relieving-purefull-cleansing-tissue/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/tea-tree-7-days-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ariul/wheat-celery-juice-cleanse-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/age-defend-conditioning-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/age-defend-replenishing-moisturiser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/age-defy-brightening-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/age-defy-nourishing-moisturiser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/age-protect-skin-vitality-moisturiser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/anti-redness-serum-c8d0ba3b-663c-4e1c-9fee-6a7f2b2afdb6/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/clearing-serum-902e8a1a-69fe-4e49-833a-b3861fffbca8/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/de-stress-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/firming-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/hydrating-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/hydration-injection-masque/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/pre-cleanse-make-up-remover/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/radiance-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/regenerating-skin-defence/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/reverse-gravity-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/skin-protector-spf-30-primer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/ark-skincare/triple-action-exfoliator/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arm-hammer/essentials-solid-deodorant-fresh/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-dreams/hydrating-hyaluronic-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-magic/aloe-vera-sunscreen-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-magic/aloe-vera-sunscreen-gel-f2bf1b6f-33e6-4c3b-b60f-684d618e68f4/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-magic/clary-sage-moisturising-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-magic/neem-and-tea-tree-face-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-magic/sunblock-lotion-spf-pa-30-uva-uvb/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-magic/vitamin-c-day-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-naturals/the-amazing-30-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma-naturals/vitamin-c-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma/anti-grafting-cream-healthy-baby-40g/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma/baby-cream-soap-with-extract-chamomile-and-smoke-tree-75g/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma/baby-moisturising-milk-for-body-250ml/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aroma/protective-face-cream-lemon/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromame/mochere-witch-cream-alaska-ice-cream-glacier-milk/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromame/mochere-witch-cream-extra-solution-cream-myrothamnus-flabellifolia/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromame/mochere-witch-cream-whitening-cream-pearl-liquid/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromame/mochere-witch-cream-wrinkle-down-cream-dragon-s-blood/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatherapy-associates/essential-skincare-moisturising-lip-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/95-natural-aloe-aqua-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/95-organic-aloe-vera-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/aloe-mineral-sunscreen-spf50-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/aloe-vitamin-e-soothing-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/argan-black-rice-5-5-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/argan-intensive-hydrating-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/argan-intensive-hydrating-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/argan-repairing-essence/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/argan-repairing-hair-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/argan-repairing-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/calendula-castile-soap/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/calendula-juicy-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/calendula-non-nano-uv-protection/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/calendula-soothing-relief-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/cypress-dust-cleansing-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/cypress-dust-shield-hair-mist/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/cypress-scalp-relief-treatment-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/damask-rose-soothing-gel/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/geranium-castile-soap/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/hibiscus-color-protection-leave-in-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/hibiscus-color-protection-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/i-m-true-natural-shampoo-with-biotin/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/i-m-true-natural-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/jerry-s-baby-hyalu-ato-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/jerry-s-baby-hyalu-daily-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/jerry-s-baby-hyalu-daily-lotion-287a8008-d0fe-4694-aac1-8a3bd017360c/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/jerry-s-baby-non-nano-sun-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/jerry-s-baby-shampoo-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lavender-relaxing-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lavender-soothing-body-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lemongrass-volumizing-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lemongrass-volumizing-treatment-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lip-nectar-nourishing-oil-natural-shine/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-body-milk-minty/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-shower-gel-minty/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-super-brite-pink-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-super-brite-vita-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-super-calming-blue-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-superbarrier-cica-pathenol-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-superbarrier-hyaluronic-acid-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-vege-cleanse-sleeping-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/lively-vita-glow-sleeping-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-coconut-cleansing-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-coconut-hand-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-jasmine-hand-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-rosewood-hand-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-tinted-sun-cover-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-tinted-sun-cover-cushion-updated-formula/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-tinted-sun-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/natural-tinted-sun-cream-light-beige-spf30-pa/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/neroli-brightening-facial-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/non-nano-sun-cushion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/orange-cleansing-sherbet/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/orange-soft-peel-toner-aha-3/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/organic-argan-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/organic-rose-absolute-nourishing-facial-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/organic-rose-hip-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/peppermint-castile-soap/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rose-absolute-eye-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rose-absolute-first-serum/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rose-absolute-vital-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rose-absolute-vital-fluid/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rosemary-hair-thickening-treatment-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rosemary-refresh-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rosemary-root-enhancer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rosemary-scalp-cleansing-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rosemary-scalp-scaling-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/rosemary-scalp-scrub/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/sea-daffodil-aqua-gel-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/sea-daffodil-aqua-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/sea-daffodil-cleansing-mousse/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/sea-daffodil-hydro-charge-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/superbarrier-hyaluronic-acid-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-53-blemish-spot/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-91-anti-blemish-calming-mask/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-balancing-emulsion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-balancing-foaming-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-balancing-toner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-green-oil/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-purifying-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-purifying-shampoo/ingredient_list#info-section",
    "https://www.skincarisma.com/products/aromatica/tea-tree-purifying-tonic/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arosa/yogic-sleep/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arrow/color-enhancing-lip-balm/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arrow/energize-skin-tint/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artdeco/green-tea-hand-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arte-dos-aromas/locao-de-limpeza-facial-copaiba-e-tea-tree/ingredient_list#info-section",
    "https://www.skincarisma.com/products/arte-dos-aromas/mascara-facial-argila-verde-e-tea-tree/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artemis-of-switzerland/eye-cream-regenerierende-augencreme/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artemis-of-switzerland/skin-aquatics-moisturising-essence-normal-dry-skin/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/anti-acne-gel-treatment/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/anti-acne-pore-refresher/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/artistry-hydra-v-fresh-foaming-cleanser/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/exact-fit-perfecting-concealer/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/exact-fit-pressed-powder-foundation/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/hydra-v-nourishing-gel-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/ideal-radiance-spot-essence-concentrate/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/light-lotion/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/multi-protect-lotion-spf-30-uva-uvb/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artistry/supreme-lx-regenerating-cream/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artnaturals/beard-conditioner/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artnaturals/pure-and-natural-body-foot-wash/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artnaturals/retinol-serum-2-5/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artnaturals/vitamin-c-serum-66008689-561a-4eea-9dbe-d54cf6e54768/ingredient_list#info-section",
    "https://www.skincarisma.com/products/artpe/first-do-clear-spot-patch/ingredient_list#info-section",
]

object = {}

def start_program(links_array, empty_object)
    counter = 1
    links_array.each do |link|
        get_basic_info(link, empty_object)
        
        puts "====================================="
        puts "#{counter} scraped."
        puts "====================================="
        
        add_to_db(@scraped_product)
        
        puts "====================================="
        puts "#{counter} added to database."
        puts "====================================="
        
        counter += 1
        empty_object = {}
    end
end

start_program(links, object)



























































# p1 = Product.create
# p1.brand = "Neutrogena"
# p1.name = "Oil-Free Acne Wash Pink Grapefruit Facial Cleanser"
# p1.category = "cleanser"
# p1.img_url = "https://target.scene7.com/is/image/Target/11537188?wid=520&hei=520&fmt=pjpeg"
# p1.sunscreen_type = nil
# p1.spf = nil
# p1.pa = nil
# p1.save

# up1 = UserProduct.create
# up1.user_id = 13
# up1.product_id = p1.id
# up1.current = false
# up1.rating = 4
# up1.wishlist = false
# up1.opened = nil
# up1.expires = nil
# up1.caused_acne = false
# up1.notes = "A little harsh and drying."
# up1.save

# i1 = Ingredient.find_or_create_by(name: "Salicylic Acid, 2%")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p1.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Water")
# i2.como_rating = nil
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p1.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Sodium C14-16 Olefin Sulfonate")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p1.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Cocamidopropyl Betaine")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p1.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Sodium Chloride")
# i5.como_rating = nil
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p1.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "PEG-120 Methyl Glucose Dioleate")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p1.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Polysorbate 20")
# i7.como_rating = 0
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p1.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Linoleamidopropyl PG-Dimonium Chloride Phosphate")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p1.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Propylene Glycol")
# i9.como_rating = 0
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p1.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "PEG-80 Sorbitan Laurate")
# i10.como_rating = nil
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p1.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Fragrance")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p1.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Disodium EDTA")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p1.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "Benzalkonium Chloride")
# i13.como_rating = nil
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p1.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "C12-15 Alkyl Lactate")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p1.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "Polyquaternium-7")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p1.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "Sodium Benzotriazolyl Butylphenol Sulfonate")
# i16.como_rating = nil
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p1.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Cocamidopropyl PG-Dimonium Chloride Phosphate")
# i17.como_rating = nil
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p1.id
# pi17.ingredient_id = i17.id
# pi17.save

# i18 = Ingredient.find_or_create_by(name: "Ascorbyl Palmitate")
# i18.como_rating = 2
# i18.save

# pi18 = ProductIngredient.create
# pi18.product_id = p1.id
# pi18.ingredient_id = i18.id
# pi18.save

# i19 = Ingredient.find_or_create_by(name: "Aloe Barbadensis Leaf Extract")
# i19.como_rating = nil
# i19.save

# pi19 = ProductIngredient.create
# pi19.product_id = p1.id
# pi19.ingredient_id = i19.id
# pi19.save

# i20 = Ingredient.find_or_create_by(name: "Anthemis Nobilis Flower Extract")
# i20.como_rating = nil
# i20.save

# pi20 = ProductIngredient.create
# pi20.product_id = p1.id
# pi20.ingredient_id = i20.id
# pi20.save

# i21 = Ingredient.find_or_create_by(name: "Chamomilla Recutita Flower Extract")
# i21.como_rating = nil
# i21.save

# pi21 = ProductIngredient.create
# pi21.product_id = p1.id
# pi21.ingredient_id = i21.id
# pi21.save

# i22 = Ingredient.find_or_create_by(name: "Citrus Grandis Fruit Extract")
# i22.como_rating = nil
# i22.save

# pi22 = ProductIngredient.create
# pi22.product_id = p1.id
# pi22.ingredient_id = i22.id
# pi22.save

# i23 = Ingredient.find_or_create_by(name: "Citric Acid")
# i23.como_rating = nil
# i23.save

# pi23 = ProductIngredient.create
# pi23.product_id = p1.id
# pi23.ingredient_id = i23.id
# pi23.save

# i24 = Ingredient.find_or_create_by(name: "Sodium Hydroxide")
# i24.como_rating = nil
# i24.save

# pi24 = ProductIngredient.create
# pi24.product_id = p1.id
# pi24.ingredient_id = i24.id
# pi24.save

# i25 = Ingredient.find_or_create_by(name: "Red 40")
# i25.como_rating = nil
# i25.save

# pi25 = ProductIngredient.create
# pi25.product_id = p1.id
# pi25.ingredient_id = i25.id
# pi25.save

# i26 = Ingredient.find_or_create_by(name: "Violet 2")
# i26.como_rating = nil
# i26.save

# pi26 = ProductIngredient.create
# pi26.product_id = p1.id
# pi26.ingredient_id = i26.id
# pi26.save

# ###################

# p2 = Product.create
# p2.brand = "Tula"
# p2.name = "Purifying Face Cleanser"
# p2.category = "cleanser"
# p2.img_url = "https://images.ulta.com/is/image/Ulta/2532485?op_sharpen=1&resMode=bilin&qlt=85&wid=800&hei=800&fmt=webp"
# p2.sunscreen_type = nil
# p2.spf = nil
# p2.pa = nil
# p2.save

# up2 = UserProduct.create
# up2.user_id = 13
# up2.product_id = p2.id
# up2.current = true
# up2.rating = 5 
# up2.wishlist = false
# up2.opened = nil
# up2.expires = nil
# up2.caused_acne = false
# up2.notes = "Holy Grail Cleanser!"
# up2.save

# i1 = Ingredient.find_or_create_by(name: "Eau")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p2.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Cocamidopropyl Betaine")
# i2.como_rating = nil
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p2.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "PEG-80 Sorbitan Laurate")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p2.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Sodium Trideceth Sulfate")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p2.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Lauryl Glucoside")
# i5.como_rating = nil
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p2.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Glycerin")
# i6.como_rating = 0
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p2.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "PEG 150 Distearate")
# i7.como_rating = 2
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p2.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Lactose")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p2.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Milk Protein")
# i9.como_rating = nil
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p2.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Bifida Ferment Lysate")
# i10.como_rating = nil
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p2.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Yogurt Extract")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p2.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Hydrolyzed Rice Protein")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p2.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "Cichorium Intybus Root Extract")
# i13.como_rating = nil
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p2.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "Vaccinium Angustifolium Fruit Extract")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p2.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "Vegetable Oil")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p2.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "Camelina Sativa Seed Oil")
# i16.como_rating = nil
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p2.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Camellia Sinensis Leaf Extract")
# i17.como_rating = nil
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p2.id
# pi17.ingredient_id = i17.id
# pi17.save

# i18 = Ingredient.find_or_create_by(name: "Curcuma Longa Root Extract")
# i18.como_rating = nil
# i18.save

# pi18 = ProductIngredient.create
# pi18.product_id = p2.id
# pi18.ingredient_id = i18.id
# pi18.save

# i19 = Ingredient.find_or_create_by(name: "Tocopheryl Acetate")
# i19.como_rating = 0
# i19.save

# pi19 = ProductIngredient.create
# pi19.product_id = p2.id
# pi19.ingredient_id = i19.id
# pi19.save

# i20 = Ingredient.find_or_create_by(name: "Retinyl Palmitate")
# i20.como_rating = 2
# i20.save

# pi20 = ProductIngredient.create
# pi20.product_id = p2.id
# pi20.ingredient_id = i20.id
# pi20.save

# i21 = Ingredient.find_or_create_by(name: "Ascorbyl Palmitate")
# i21.como_rating = 2
# i21.save

# pi21 = ProductIngredient.create
# pi21.product_id = p2.id
# pi21.ingredient_id = i21.id
# pi21.save

# i22 = Ingredient.find_or_create_by(name: "Panthenol")
# i22.como_rating = 0
# i22.save

# pi22 = ProductIngredient.create
# pi22.product_id = p2.id
# pi22.ingredient_id = i22.id
# pi22.save

# i23 = Ingredient.find_or_create_by(name: "Carthamus Tinctorius Seed Oil")
# i23.como_rating = 0
# i23.save

# pi23 = ProductIngredient.create
# pi23.product_id = p2.id
# pi23.ingredient_id = i23.id
# pi23.save

# i24 = Ingredient.find_or_create_by(name: "Polyquaternium-10")
# i24.como_rating = nil
# i24.save

# pi24 = ProductIngredient.create
# pi24.product_id = p2.id
# pi24.ingredient_id = i24.id
# pi24.save

# i25 = Ingredient.find_or_create_by(name: "Butylene Glycol")
# i25.como_rating = 1
# i25.save

# pi25 = ProductIngredient.create
# pi25.product_id = p2.id
# pi25.ingredient_id = i25.id
# pi25.save

# i26 = Ingredient.find_or_create_by(name: "Sodium Chloride")
# i26.como_rating = nil
# i26.save

# pi26 = ProductIngredient.create
# pi26.product_id = p2.id
# pi26.ingredient_id = i26.id
# pi26.save

# i27 = Ingredient.find_or_create_by(name: "Pentylene Glycol")
# i27.como_rating = nil
# i27.save

# pi27 = ProductIngredient.create
# pi27.product_id = p2.id
# pi27.ingredient_id = i27.id
# pi27.save

# i28 = Ingredient.find_or_create_by(name: "Caprylyl Glycol")
# i28.como_rating = nil
# i28.save

# pi28 = ProductIngredient.create
# pi28.product_id = p2.id
# pi28.ingredient_id = i28.id
# pi28.save

# i29 = Ingredient.find_or_create_by(name: "Ethylhexylglycerin")
# i29.como_rating = nil
# i29.save

# pi29 = ProductIngredient.create
# pi29.product_id = p2.id
# pi29.ingredient_id = i29.id
# pi29.save

# i30 = Ingredient.find_or_create_by(name: "Bulnesia Sarmientoi Wood Oil")
# i30.como_rating = nil
# i30.save

# pi30 = ProductIngredient.create
# pi30.product_id = p2.id
# pi30.ingredient_id = i30.id
# pi30.save

# i31 = Ingredient.find_or_create_by(name: "Citrus Limon Fruit Oil")
# i31.como_rating = nil
# i31.save

# pi31 = ProductIngredient.create
# pi31.product_id = p2.id
# pi31.ingredient_id = i31.id
# pi31.save

# i32 = Ingredient.find_or_create_by(name: "Citrus Aurantium Dulcis (Orange) Oil")
# i32.como_rating = nil
# i32.save

# pi32 = ProductIngredient.create
# pi32.product_id = p2.id
# pi32.ingredient_id = i32.id
# pi32.save

# i33 = Ingredient.find_or_create_by(name: "Juniperus Mexicana Oil")
# i33.como_rating = nil
# i33.save

# pi33 = ProductIngredient.create
# pi33.product_id = p2.id
# pi33.ingredient_id = i33.id
# pi33.save

# i34 = Ingredient.find_or_create_by(name: "Cananga Odorata Flower Oil")
# i34.como_rating = nil
# i34.save

# pi34 = ProductIngredient.create
# pi34.product_id = p2.id
# pi34.ingredient_id = i34.id
# pi34.save

# i35 = Ingredient.find_or_create_by(name: "Fragrance")
# i35.como_rating = nil
# i35.save

# pi35 = ProductIngredient.create
# pi35.product_id = p2.id
# pi35.ingredient_id = i35.id
# pi35.save

# i36 = Ingredient.find_or_create_by(name: "Sorbic Acid")
# i36.como_rating = nil
# i36.save

# pi36 = ProductIngredient.create
# pi36.product_id = p2.id
# pi36.ingredient_id = i36.id
# pi36.save

# i37 = Ingredient.find_or_create_by(name: "Phenoxyethanol")
# i37.como_rating = nil
# i37.save

# pi37 = ProductIngredient.create
# pi37.product_id = p2.id
# pi37.ingredient_id = i37.id
# pi37.save

# i38 = Ingredient.find_or_create_by(name: "Disodium EDTA")
# i38.como_rating = nil
# i38.save

# pi38 = ProductIngredient.create
# pi38.product_id = p2.id
# pi38.ingredient_id = i38.id
# pi38.save

# i39 = Ingredient.find_or_create_by(name: "Methylchloroisothiazolinone")
# i39.como_rating = nil
# i39.save

# pi39 = ProductIngredient.create
# pi39.product_id = p2.id
# pi39.ingredient_id = i39.id
# pi39.save

# i40 = Ingredient.find_or_create_by(name: "Methylisothiazolinone")
# i40.como_rating = nil
# i40.save

# pi40 = ProductIngredient.create
# pi40.product_id = p2.id
# pi40.ingredient_id = i40.id
# pi40.save

# ###################

# p3 = Product.create
# p3.brand = "Cetaphil"
# p3.name = "Gentle Skin Cleanser"
# p3.category = "cleanser"
# p3.img_url = "https://s3-ap-southeast-1.amazonaws.com/skincarisma-staging/submitted_images/files/000/013/389/medium/cetaphil-gentle-skin-cleanser.jpg?1521899667"
# p3.sunscreen_type = nil
# p3.spf = nil
# p3.pa = nil
# p3.save

# up3 = UserProduct.create
# up3.user_id = 13
# up3.product_id = p3.id
# up3.current = false
# up3.rating = 1
# up3.wishlist = false
# up3.opened = nil
# up3.expires = nil
# up3.caused_acne = true
# up3.notes = "Caused cystic acne breakout."
# up3.save

# i1 = Ingredient.find_or_create_by(name: "Water")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p3.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Cetyl Alcohol")
# i2.como_rating = 2
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p3.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Propylene Glycol")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p3.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Sodium Lauryl Sulfate")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p3.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Stearyl Alcohol")
# i5.como_rating = 2
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p3.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Methylparaben")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p3.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Propylparaben")
# i7.como_rating = 0
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p3.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Butylparaben")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p3.id
# pi8.ingredient_id = i8.id
# pi8.save

# ###################

# p4 = Product.create
# p4.brand = "Hada Labo"
# p4.name = "Gokujyun Perfect Gel"
# p4.category = "Moisturizer"
# p4.img_url = "https://cdn.shopify.com/s/files/1/1795/7013/products/4_3bff5922-c769-4be8-a8db-39ab1c4ad837_1200x.png?v=1522270844"
# p4.sunscreen_type = nil
# p4.spf = nil
# p4.pa = nil
# p4.save

# up4 = UserProduct.create
# up4.user_id = 13
# up4.product_id = p4.id
# up4.current = true
# up4.rating = 5
# up4.wishlist = false
# up4.opened = nil
# up4.expires = nil
# up4.caused_acne = false
# up4.notes = "Holy Grail Moisturizer!"
# up4.save

# i1 = Ingredient.find_or_create_by(name: "Water")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p4.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Butylene Glycol")
# i2.como_rating = 1
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p4.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Hydroxyethyl Urea")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p4.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Pentylene Glycol")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p4.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Glycerin")
# i5.como_rating = 0
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p4.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Squalane")
# i6.como_rating = 1
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p4.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "PEG/PPG/Polybutylene Glycol-8/5/3 Glycerin")
# i7.como_rating = nil
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p4.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Triethylhexanoin")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p4.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Ammonium Acryloyldimethyltaurate/VP Copolymer")
# i9.como_rating = nil
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p4.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Agar")
# i10.como_rating = nil
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p4.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Arginine")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p4.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Dextrin")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p4.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "Dimethicone")
# i13.como_rating = 1
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p4.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "Disodium EDTA")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p4.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "Disodium Succinate")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p4.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "Glucosyl Ceramide")
# i16.como_rating = nil
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p4.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Hydrolyzed Collagen")
# i17.como_rating = 0
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p4.id
# pi17.ingredient_id = i17.id
# pi17.save

# i18 = Ingredient.find_or_create_by(name: "Hydrolyzed Hyaluronic Acid")
# i18.como_rating = nil
# i18.save

# pi18 = ProductIngredient.create
# pi18.product_id = p4.id
# pi18.ingredient_id = i18.id
# pi18.save

# i19 = Ingredient.find_or_create_by(name: "Methylparaben")
# i19.como_rating = 0
# i19.save

# pi19 = ProductIngredient.create
# pi19.product_id = p4.id
# pi19.ingredient_id = i19.id
# pi19.save

# i20 = Ingredient.find_or_create_by(name: "Phenoxyethanol")
# i20.como_rating = nil
# i20.save

# pi20 = ProductIngredient.create
# pi20.product_id = p4.id
# pi20.ingredient_id = i20.id
# pi20.save

# i21 = Ingredient.find_or_create_by(name: "Propylparaben")
# i21.como_rating = 0
# i21.save

# pi21 = ProductIngredient.create
# pi21.product_id = p4.id
# pi21.ingredient_id = i21.id
# pi21.save

# i22 = Ingredient.find_or_create_by(name: "Sodium Acetylated Hyaluronate")
# i22.como_rating = nil
# i22.save

# pi22 = ProductIngredient.create
# pi22.product_id = p4.id
# pi22.ingredient_id = i22.id
# pi22.save

# i23 = Ingredient.find_or_create_by(name: "Sodium Hyaluronate")
# i23.como_rating = 0
# i23.save

# pi23 = ProductIngredient.create
# pi23.product_id = p4.id
# pi23.ingredient_id = i23.id
# pi23.save

# i24 = Ingredient.find_or_create_by(name: "Succinic Acid")
# i24.como_rating = nil
# i24.save

# pi24 = ProductIngredient.create
# pi24.product_id = p4.id
# pi24.ingredient_id = i24.id
# pi24.save

# i25 = Ingredient.find_or_create_by(name: "Triethyl Citrate")
# i25.como_rating = nil
# i25.save

# pi25 = ProductIngredient.create
# pi25.product_id = p4.id
# pi25.ingredient_id = i25.id
# pi25.save

# ###################

# p5 = Product.create
# p5.brand = "Stridex"
# p5.name = "Maximum"
# p5.category = "Active"
# p5.img_url = "https://pics.drugstore.com/prodimg/151226/900.jpg"
# p5.sunscreen_type = nil
# p5.spf = nil
# p5.pa = nil
# p5.save

# up5 = UserProduct.create
# up5.user_id = 13
# up5.product_id = p5.id
# up5.current = false
# up5.rating = 4 
# up5.wishlist = false
# up5.opened = nil
# up5.expires = nil
# up5.caused_acne = false
# up5.notes = "Drying but effective."
# up5.save

# i1 = Ingredient.find_or_create_by(name: "Salicylic Acid, 2%")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p5.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Aminomethyl Propanol")
# i2.como_rating = nil
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p5.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Ammonium Xylenesulfonate")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p5.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Citric Acid")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p5.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "DMDM Hydantoin")
# i5.como_rating = nil
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p5.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Fragrance")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p5.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Menthol")
# i7.como_rating = nil
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p5.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "PPG-5-Ceteth-20")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p5.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Water")
# i9.como_rating = nil
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p5.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Simethicone")
# i10.como_rating = 1
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p5.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Sodium Borate")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p5.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Tetrasodium EDTA")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p5.id
# pi12.ingredient_id = i12.id
# pi12.save

# ###################

# p6 = Product.create
# p6.brand = "Canmake"
# p6.name = "Mermaid Skin Gel UV SPF50+ PA++++"
# p6.category = "sunscreen"
# p6.img_url = "https://s3-ap-southeast-1.amazonaws.com/skincarisma-staging/submitted_images/files/000/049/306/medium/mermaid-skin-gel-uv-spf50-pa.jpg?1549908900"
# p6.sunscreen_type = "chemical"
# p6.spf = "50"
# p6.pa = "++++"
# p6.save

# up6 = UserProduct.create
# up6.user_id = 13
# up6.product_id = p6.id
# up6.current = false
# up6.rating = 4
# up6.wishlist = false
# up6.opened = nil
# up6.expires = nil
# up6.caused_acne = true
# up6.notes = "Perfect consistency, but caused acne."
# up6.save

# i1 = Ingredient.find_or_create_by(name: "Water")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p6.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Ethylhexyl Methoxycinnamate")
# i2.como_rating = 0
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p6.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Butylene Glycol")
# i3.como_rating = 1
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p6.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Diethylamino Hydroxybenzoyl Hexyl Benzoate")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p6.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Zinc Oxide")
# i5.como_rating = 1
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p6.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Methylheptyl Isostearate")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p6.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Titanium Dioxide")
# i7.como_rating = 0
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p6.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Dimethicone")
# i8.como_rating = 1
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p6.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine")
# i9.como_rating = nil
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p6.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Polymethylsilsesquioxane")
# i10.como_rating = nil
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p6.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Cyclopentasiloxane")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p6.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Acryloyldimethyltaurate/VP Copolymer")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p6.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "Diisostearyl Malate")
# i13.como_rating = nil
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p6.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "Aluminum Hydroxide")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p6.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "PEG-60 Hydrogenated Castor Oil")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p6.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "Stearic Acid")
# i16.como_rating = 3
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p6.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Phenoxyethanol")
# i17.como_rating = nil
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p6.id
# pi17.ingredient_id = i17.id
# pi17.save

# i18 = Ingredient.find_or_create_by(name: "Polyglyceryl-3 Polydimethylsiloxyethyl Dimethicone")
# i18.como_rating = nil
# i18.save

# pi18 = ProductIngredient.create
# pi18.product_id = p6.id
# pi18.ingredient_id = i18.id
# pi18.save

# i19 = Ingredient.find_or_create_by(name: "Polyhydroxystearic Acid")
# i19.como_rating = nil
# i19.save

# pi19 = ProductIngredient.create
# pi19.product_id = p6.id
# pi19.ingredient_id = i19.id
# pi19.save

# i20 = Ingredient.find_or_create_by(name: "Jojoba Esters")
# i20.como_rating = nil
# i20.save

# pi20 = ProductIngredient.create
# pi20.product_id = p6.id
# pi20.ingredient_id = i20.id
# pi20.save

# i21 = Ingredient.find_or_create_by(name: "Xanthan Gum")
# i21.como_rating = nil
# i21.save

# pi21 = ProductIngredient.create
# pi21.product_id = p6.id
# pi21.ingredient_id = i21.id
# pi21.save

# i22 = Ingredient.find_or_create_by(name: "Arginine")
# i22.como_rating = nil
# i22.save

# pi22 = ProductIngredient.create
# pi22.product_id = p6.id
# pi22.ingredient_id = i22.id
# pi22.save

# i23 = Ingredient.find_or_create_by(name: "Hyaluronic Acid")
# i23.como_rating = nil
# i23.save

# pi23 = ProductIngredient.create
# pi23.product_id = p6.id
# pi23.ingredient_id = i23.id
# pi23.save

# i24 = Ingredient.find_or_create_by(name: "Alpha-Glucan")
# i24.como_rating = nil
# i24.save

# pi24 = ProductIngredient.create
# pi24.product_id = p6.id
# pi24.ingredient_id = i24.id
# pi24.save

# i25 = Ingredient.find_or_create_by(name: "Phytic Acid")
# i25.como_rating = nil
# i25.save

# pi25 = ProductIngredient.create
# pi25.product_id = p6.id
# pi25.ingredient_id = i25.id
# pi25.save

# i26 = Ingredient.find_or_create_by(name: "Saxifraga Sarmentosa Extract")
# i26.como_rating = nil
# i26.save

# pi26 = ProductIngredient.create
# pi26.product_id = p6.id
# pi26.ingredient_id = i26.id
# pi26.save

# i27 = Ingredient.find_or_create_by(name: "Glucosyl Ceramide")
# i27.como_rating = nil
# i27.save

# pi27 = ProductIngredient.create
# pi27.product_id = p6.id
# pi27.ingredient_id = i27.id
# pi27.save

# i28 = Ingredient.find_or_create_by(name: "Prunus Yedoensis Leaf Extract")
# i28.como_rating = nil
# i28.save

# pi28 = ProductIngredient.create
# pi28.product_id = p6.id
# pi28.ingredient_id = i28.id
# pi28.save

# i29 = Ingredient.find_or_create_by(name: "Coix Lacryma-Jobi Ma-yuen (Job's Tears)")
# i29.como_rating = nil
# i29.save

# pi29 = ProductIngredient.create
# pi29.product_id = p6.id
# pi29.ingredient_id = i29.id
# pi29.save

# i30 = Ingredient.find_or_create_by(name: "Morus Alba Root Extract")
# i30.como_rating = nil
# i30.save

# pi30 = ProductIngredient.create
# pi30.product_id = p6.id
# pi30.ingredient_id = i30.id
# pi30.save

# i31 = Ingredient.find_or_create_by(name: "Oenothera Biennis (Evening Primrose) Seed Extract")
# i31.como_rating = nil
# i31.save

# pi31 = ProductIngredient.create
# pi31.product_id = p6.id
# pi31.ingredient_id = i31.id
# pi31.save

# i32 = Ingredient.find_or_create_by(name: "Silver Oxide")
# i32.como_rating = nil
# i32.save

# pi32 = ProductIngredient.create
# pi32.product_id = p6.id
# pi32.ingredient_id = i32.id
# pi32.save

# i33 = Ingredient.find_or_create_by(name: "Spiraea Ulmaria Flower Extract")
# i33.como_rating = nil
# i33.save

# pi33 = ProductIngredient.create
# pi33.product_id = p6.id
# pi33.ingredient_id = i33.id
# pi33.save

# i34 = Ingredient.find_or_create_by(name: "Vaccinium Myrtillus (Bilberry) Extract")
# i34.como_rating = nil
# i34.save

# pi34 = ProductIngredient.create
# pi34.product_id = p6.id
# pi34.ingredient_id = i34.id
# pi34.save

# i35 = Ingredient.find_or_create_by(name: "Cynara Scolymus (Artichoke) Leaf Extract")
# i35.como_rating = nil
# i35.save

# pi35 = ProductIngredient.create
# pi35.product_id = p6.id
# pi35.ingredient_id = i35.id
# pi35.save

# ###################

# p7 = Product.create
# p7.brand = "Banila Co."
# p7.name = "Clean It Zero"
# p7.category = "cleanser"
# p7.img_url = "https://s3-ap-southeast-1.amazonaws.com/skincarisma-staging/submitted_images/files/000/050/083/medium/clean-it-zero-classic.jpg?1549911801"
# p7.sunscreen_type = nil
# p7.spf = nil
# p7.pa = nil
# p7.save

# up7 = UserProduct.create
# up7.user_id = 13
# up7.product_id = p7.id
# up7.current = false
# up7.rating = 5
# up7.wishlist = false
# up7.opened = nil
# up7.expires =  nil
# up7.caused_acne = false
# up7.notes = nil
# up7.save

# i1 = Ingredient.find_or_create_by(name: "Mineral Oil")
# i1.como_rating = 2
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p7.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Cetyl Ethylhexanoate")
# i2.como_rating = nil
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p7.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "PEG-20 Glyceryl Triisostearate")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p7.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "PEG-10 Isostearate")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p7.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Polyethylene")
# i5.como_rating = nil
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p7.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Butylene Glycol")
# i6.como_rating = 1
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p7.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Water")
# i7.como_rating = nil
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p7.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Rubus Suavissimus (Raspberry) Leaf Extract")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p7.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Bambusa Arundinacea Stem Extract")
# i9.como_rating = nil
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p7.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Aspalathus Linearis Leaf Extract")
# i10.como_rating = nil
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p7.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Viscum Album (Mistletoe) Leaf Extract")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p7.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Angelica Polymorpha Sinensis Root Extract")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p7.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "Carica Papaya (Papaya) Fruit Extract")
# i13.como_rating = nil
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p7.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "Malpighia Glabra (Acerola) Fruit Extract")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p7.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "Epilobium Angustifolium Leaf Extract")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p7.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "BHT")
# i16.como_rating = nil
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p7.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Butylparaben")
# i17.como_rating = nil
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p7.id
# pi17.ingredient_id = i17.id
# pi17.save

# i18 = Ingredient.find_or_create_by(name: "CI 16255")
# i18.como_rating = nil
# i18.save

# pi18 = ProductIngredient.create
# pi18.product_id = p7.id
# pi18.ingredient_id = i18.id
# pi18.save

# i19 = Ingredient.find_or_create_by(name: "CI 15985")
# i19.como_rating = nil
# i19.save

# pi19 = ProductIngredient.create
# pi19.product_id = p7.id
# pi19.ingredient_id = i19.id
# pi19.save

# i20 = Ingredient.find_or_create_by(name: "Fragrance")
# i20.como_rating = nil
# i20.save

# pi20 = ProductIngredient.create
# pi20.product_id = p7.id
# pi20.ingredient_id = i20.id
# pi20.save

# ###################

# p8 = Product.create
# p8.brand = "Blue Lizard"
# p8.name = "Face"
# p8.category = "Sunscreen"
# p8.img_url = "https://i5.walmartimages.com/asr/a5cece97-f266-49c9-9fdf-d0aec3b51895_1.462e41e61a5ce3f49bc44f9c57321269.jpeg?odnWidth=450&odnHeight=450&odnBg=ffffff"
# p8.sunscreen_type = "chemical"
# p8.spf = "30+"
# p8.pa = nil
# p8.save

# i1 = Ingredient.find_or_create_by(name: "Cinoxate")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p8.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Zinc Oxide")
# i2.como_rating = 1
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p8.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Water")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p8.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "C12-15 Alkyl Benzoate")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p8.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Cyclomethicone")
# i5.como_rating = 1
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p8.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Lauryl PEG/PPG-18/18 Methicone")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p8.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Polyacrylamide")
# i7.como_rating = nil
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p8.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "C13-14 Isoparaffin")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p8.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Laureth-7")
# i9.como_rating = nil
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p8.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Tocopheryl Acetate (Vitamin E)")
# i10.como_rating = 0
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p8.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Hyaluronic Acid")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p8.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Camellia Sinensis (Green Tea) Leaf Extract")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p8.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "PEG-8 Beeswax")
# i13.como_rating = nil
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p8.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "Caffeine")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p8.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "Diazolidinyl Urea")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p8.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "Methylparaben")
# i16.como_rating = 0
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p8.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Propylparaben")
# i17.como_rating = nil
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p8.id
# pi17.ingredient_id = i17.id
# pi17.save

# ###################

# p9 = Product.create
# p9.brand = "COSRX"
# p9.name = "Ultimate Moisturizing Honey Overnight Mask"
# p9.category = "mask"
# p9.img_url = "https://cdn10.bigcommerce.com/s-6dbw5r/products/361/images/1647/1a8ebcccf3c6dbfda81a23bd599e3839__92388.1537308871.400.400.jpg?c=2"
# p9.sunscreen_type = nil
# p9.spf = nil
# p9.pa = nil
# p9.save

# i1 = Ingredient.find_or_create_by(name: "Propolis Extract")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p9.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Butylene Glycol")
# i2.como_rating = 1
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p9.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Glycerin")
# i3.como_rating = nil
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p9.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Betaine")
# i4.como_rating = nil
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p9.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "1,2-Hexanediol")
# i5.como_rating = nil
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p9.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "PEG-60 Hydrogenated Castor Oil")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p9.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Arginine")
# i7.como_rating = nil
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p9.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Cassia Obtusifolia Seed Extract")
# i8.como_rating = nil
# i8.save

# pi8 = ProductIngredient.create
# pi8.product_id = p9.id
# pi8.ingredient_id = i8.id
# pi8.save

# i9 = Ingredient.find_or_create_by(name: "Dimethicone")
# i9.como_rating = 1
# i9.save

# pi9 = ProductIngredient.create
# pi9.product_id = p9.id
# pi9.ingredient_id = i9.id
# pi9.save

# i10 = Ingredient.find_or_create_by(name: "Ethylhexylglycerin")
# i10.como_rating = nil
# i10.save

# pi10 = ProductIngredient.create
# pi10.product_id = p9.id
# pi10.ingredient_id = i10.id
# pi10.save

# i11 = Ingredient.find_or_create_by(name: "Carbomer")
# i11.como_rating = nil
# i11.save

# pi11 = ProductIngredient.create
# pi11.product_id = p9.id
# pi11.ingredient_id = i11.id
# pi11.save

# i12 = Ingredient.find_or_create_by(name: "Sodium Hyaluronate")
# i12.como_rating = nil
# i12.save

# pi12 = ProductIngredient.create
# pi12.product_id = p9.id
# pi12.ingredient_id = i12.id
# pi12.save

# i13 = Ingredient.find_or_create_by(name: "PEG-8 Beeswax")
# i13.como_rating = nil
# i13.save

# pi13 = ProductIngredient.create
# pi13.product_id = p9.id
# pi13.ingredient_id = i13.id
# pi13.save

# i14 = Ingredient.find_or_create_by(name: "Allantoin")
# i14.como_rating = nil
# i14.save

# pi14 = ProductIngredient.create
# pi14.product_id = p9.id
# pi14.ingredient_id = i14.id
# pi14.save

# i15 = Ingredient.find_or_create_by(name: "Panthenol")
# i15.como_rating = nil
# i15.save

# pi15 = ProductIngredient.create
# pi15.product_id = p9.id
# pi15.ingredient_id = i15.id
# pi15.save

# i16 = Ingredient.find_or_create_by(name: "Sodium Polyacrylate")
# i16.como_rating = nil
# i16.save

# pi16 = ProductIngredient.create
# pi16.product_id = p9.id
# pi16.ingredient_id = i16.id
# pi16.save

# i17 = Ingredient.find_or_create_by(name: "Adenosine")
# i17.como_rating = nil
# i17.save

# pi17 = ProductIngredient.create
# pi17.product_id = p9.id
# pi17.ingredient_id = i17.id
# pi17.save

# ###################

# p10 = Product.create
# p10.brand = "Queen Helene"
# p10.name = "Mint Julep Masque"
# p10.category = "XYZ"
# p10.img_url = "https://images-na.ssl-images-amazon.com/images/I/71RDIOVPNbL._SL1500_.jpg"
# p10.sunscreen_type = nil
# p10.spf = nil
# p10.pa = nil
# p10.save

# i1 = Ingredient.find_or_create_by(name: "Water")
# i1.como_rating = nil
# i1.save

# pi1 = ProductIngredient.create
# pi1.product_id = p10.id
# pi1.ingredient_id = i1.id
# pi1.save

# i2 = Ingredient.find_or_create_by(name: "Kaolin")
# i2.como_rating = 0
# i2.save

# pi2 = ProductIngredient.create
# pi2.product_id = p10.id
# pi2.ingredient_id = i2.id
# pi2.save

# i3 = Ingredient.find_or_create_by(name: "Bentonite")
# i3.como_rating = 0
# i3.save

# pi3 = ProductIngredient.create
# pi3.product_id = p10.id
# pi3.ingredient_id = i3.id
# pi3.save

# i4 = Ingredient.find_or_create_by(name: "Glycerin")
# i4.como_rating = 0
# i4.save

# pi4 = ProductIngredient.create
# pi4.product_id = p10.id
# pi4.ingredient_id = i4.id
# pi4.save

# i5 = Ingredient.find_or_create_by(name: "Chromium Oxide Greens")
# i5.como_rating = nil
# i5.save

# pi5 = ProductIngredient.create
# pi5.product_id = p10.id
# pi5.ingredient_id = i5.id
# pi5.save

# i6 = Ingredient.find_or_create_by(name: "Fragrance")
# i6.como_rating = nil
# i6.save

# pi6 = ProductIngredient.create
# pi6.product_id = p10.id
# pi6.ingredient_id = i6.id
# pi6.save

# i7 = Ingredient.find_or_create_by(name: "Phenoxyethanol")
# i7.como_rating = nil
# i7.save

# pi7 = ProductIngredient.create
# pi7.product_id = p10.id
# pi7.ingredient_id = i7.id
# pi7.save

# i8 = Ingredient.find_or_create_by(name: "Methylparaben")
# i8.como_rating = 0
# i8.save