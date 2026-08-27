//
//  ProductCatalog.swift
//  shop-sdk
//
//  Created by Sushant Verma on 15/8/2026 for [/dev/world 2026](https://devworld.au/)
//

import Foundation

/// Static seed data for the demo shop's product catalog.
enum ProductCatalog {
    /// The full fixed list of products the app ships with, grouped by category (produce, dairy, pantry, etc).
    static let all: [Product] = [
        Product(
            id: "spinach",
            name: "Spinach",
            description: "A leafy green with tender, dark leaves, popular raw in salads or wilted down as a cooked side.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/37/Spinacia_oleracea_Spinazie_bloeiend.jpg",
            unitPrice: 2.50,
            tags: [.vegetable],
            recipeIdeas: ["Creamed spinach", "Spinach and feta pie", "Wilted spinach with garlic and lemon"],
            popularity: 0.65
        ),
        Product(
            id: "lettuce",
            name: "Lettuce",
            description: "Crisp, mild-flavored leaves that form the base of most garden salads and sandwiches.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/da/Iceberg_lettuce_in_SB.jpg",
            unitPrice: 2.00,
            tags: [.vegetable],
            recipeIdeas: ["Classic garden salad", "Lettuce wraps", "Caesar salad"],
            popularity: 0.7
        ),
        Product(
            id: "kale",
            name: "Kale",
            description: "A hearty, slightly bitter leafy green that holds up well to roasting, sautéing, and long braises.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/20/Boerenkool.jpg",
            unitPrice: 2.75,
            tags: [.vegetable],
            recipeIdeas: ["Massaged kale salad", "Crispy kale chips", "Kale and white bean soup"],
            popularity: 0.55
        ),
        Product(
            id: "silverbeet",
            name: "Silverbeet",
            description: "Also known as chard, with broad ribbed leaves and colorful stalks that cook down into a tender, earthy green.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/45/Chard_%28Beta_vulgaris_var_cicla%29.jpg",
            unitPrice: 2.50,
            tags: [.vegetable],
            recipeIdeas: ["Sautéed silverbeet with garlic", "Silverbeet and ricotta gozleme", "Stem-and-leaf stir-fry"],
            popularity: 0.3
        ),
        Product(
            id: "cabbage",
            name: "Cabbage",
            description: "A dense, tightly layered head of leaves that stays crunchy raw and turns sweet when slow-cooked.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/6f/Cabbage_and_cross_section_on_white.jpg",
            unitPrice: 1.80,
            tags: [.vegetable],
            recipeIdeas: ["Coleslaw", "Braised cabbage with bacon", "Cabbage stir-fry"],
            popularity: 0.5
        ),
        Product(
            id: "broccoli",
            name: "Broccoli",
            description: "Tight green florets on edible stalks, best roasted until charred at the edges or steamed until just tender.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/03/Broccoli_and_cross_section_edit.jpg",
            unitPrice: 2.20,
            tags: [.vegetable],
            recipeIdeas: ["Roasted broccoli with garlic", "Broccoli cheddar soup", "Beef and broccoli stir-fry"],
            popularity: 0.75
        ),
        Product(
            id: "cauliflower",
            name: "Cauliflower",
            description: "A mild, versatile brassica with dense white curds that can be roasted whole, riced, or mashed.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Chou-fleur_02.jpg/3840px-Chou-fleur_02.jpg",
            unitPrice: 2.90,
            tags: [.vegetable],
            recipeIdeas: ["Whole roasted cauliflower", "Cauliflower rice", "Cauliflower cheese bake"],
            popularity: 0.6
        ),
        Product(
            id: "brussels-sprouts",
            name: "Brussels sprouts",
            description: "Miniature cabbage-like buds with a nutty flavor that deepens when roasted or pan-seared until crisp.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/23/Brussels_sprout_closeup.jpg",
            unitPrice: 3.20,
            tags: [.vegetable],
            recipeIdeas: ["Crispy roasted brussels sprouts", "Shaved sprout salad", "Brussels sprouts with bacon and balsamic"],
            popularity: 0.4
        ),
        Product(
            id: "carrots",
            name: "Carrots",
            description: "Sweet, crunchy root vegetables good eaten raw, roasted whole, or shredded into salads.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Vegetable-Carrot-Bundle-wStalks.jpg/3840px-Vegetable-Carrot-Bundle-wStalks.jpg",
            unitPrice: 1.50,
            tags: [.vegetable],
            recipeIdeas: ["Honey-glazed roasted carrots", "Carrot and ginger soup", "Classic carrot cake"],
            popularity: 0.9
        ),
        Product(
            id: "potatoes",
            name: "Potatoes",
            description: "A starchy, filling staple root vegetable that can be boiled, roasted, mashed, or fried.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ab/Patates.jpg",
            unitPrice: 1.20,
            tags: [.vegetable],
            recipeIdeas: ["Crispy roast potatoes", "Creamy mashed potatoes", "Classic potato salad"],
            popularity: 0.95
        ),
        Product(
            id: "sweet-potatoes",
            name: "Sweet potatoes",
            description: "A naturally sweet, orange-fleshed tuber that caramelizes beautifully when roasted or baked whole.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/5/58/Ipomoea_batatas_006.JPG",
            unitPrice: 1.80,
            tags: [.vegetable],
            recipeIdeas: ["Baked sweet potato with toppings", "Sweet potato fries", "Sweet potato and coconut curry"],
            popularity: 0.7
        ),
        Product(
            id: "beets",
            name: "Beets",
            description: "Earthy, deep-red root vegetables that roast into a tender sweetness and stain everything a vivid magenta.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ae/Detroitdarkredbeets.png",
            unitPrice: 2.00,
            tags: [.vegetable],
            recipeIdeas: ["Roasted beet and goat cheese salad", "Pickled beets", "Beet and orange salad"],
            popularity: 0.35
        ),
        Product(
            id: "onions",
            name: "Onions",
            description: "A pungent aromatic bulb that softens and sweetens with cooking, forming the base of countless savory dishes.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/a2/Mixed_onions.jpg",
            unitPrice: 1.00,
            tags: [.vegetable],
            recipeIdeas: ["Caramelized onions", "French onion soup", "Crispy onion rings"],
            popularity: 0.92
        ),
        Product(
            id: "garlic",
            name: "Garlic",
            description: "A small, intensely flavored bulb whose cloves are essential to savory cooking across nearly every cuisine.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/39/Allium_sativum_Woodwill_1793.jpg",
            unitPrice: 0.50,
            tags: [.vegetable],
            recipeIdeas: ["Roasted garlic spread", "Garlic butter shrimp", "Garlic confit"],
            popularity: 0.85
        ),
        Product(
            id: "leeks",
            name: "Leeks",
            description: "A mild, slightly sweet member of the onion family with long white-and-green stalks, great braised or in soups.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/63/Leek_on_white_background_-_0947.jpg",
            unitPrice: 2.30,
            tags: [.vegetable],
            recipeIdeas: ["Potato and leek soup", "Braised leeks with butter", "Leek and gruyère tart"],
            popularity: 0.4
        ),
        Product(
            id: "tomatoes",
            name: "Tomatoes",
            description: "Juicy, glossy fruit-vegetables ranging from tangy to sweet, equally good raw, roasted, or simmered into sauce.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/89/Tomato_je.jpg",
            unitPrice: 2.60,
            tags: [.vegetable],
            recipeIdeas: ["Classic tomato sauce", "Caprese salad", "Slow-roasted cherry tomatoes"],
            popularity: 0.93
        ),
        Product(
            id: "capsicum",
            name: "Capsicum (bell peppers)",
            description: "Crisp, sweet peppers in shades of green, yellow, and red, eaten raw, stuffed, or charred over high heat.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/85/Green-Yellow-Red-Pepper-2009.jpg",
            unitPrice: 1.50,
            tags: [.vegetable],
            recipeIdeas: ["Stuffed bell peppers", "Fajita-style peppers and onions", "Roasted red pepper dip"],
            popularity: 0.75
        ),
        Product(
            id: "eggplant",
            name: "Eggplant (aubergine)",
            description: "A glossy purple nightshade with spongy flesh that turns creamy and rich when roasted or grilled.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/76/Solanum_melongena_24_08_2012_%281%29.JPG",
            unitPrice: 2.10,
            tags: [.vegetable],
            recipeIdeas: ["Eggplant parmesan", "Smoky baba ganoush", "Grilled eggplant with tahini"],
            popularity: 0.55
        ),
        Product(
            id: "oranges",
            name: "Oranges",
            description: "A juicy citrus fruit with a thick peel and sweet-tart segments, eaten fresh or squeezed for juice.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Oranges_-_whole-halved-segment.jpg/3840px-Oranges_-_whole-halved-segment.jpg",
            unitPrice: 0.80,
            tags: [.fruit],
            recipeIdeas: ["Fresh-squeezed orange juice", "Orange and fennel salad", "Orange olive oil cake"],
            popularity: 0.8
        ),
        Product(
            id: "lemons",
            name: "Lemons",
            description: "A bright, sour citrus fruit whose juice and zest lift both sweet and savory dishes.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/e4/P1030323.JPG",
            unitPrice: 0.60,
            tags: [.fruit],
            recipeIdeas: ["Lemon curd", "Lemon garlic roast chicken", "Homemade lemonade"],
            popularity: 0.78
        ),
        Product(
            id: "limes",
            name: "Limes",
            description: "A small, tart green citrus fruit prized for its sharp, aromatic juice and zest.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/8b/Lime_Blossom.jpg",
            unitPrice: 0.50,
            tags: [.fruit],
            recipeIdeas: ["Classic guacamole", "Lime and coriander rice", "Fresh limeade"],
            popularity: 0.65
        ),
        Product(
            id: "grapefruits",
            name: "Grapefruits",
            description: "A large citrus fruit with juicy, tangy-sweet flesh in shades from pale yellow to deep pink.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Grapefruits_-_whole-halved-segments.jpg/3840px-Grapefruits_-_whole-halved-segments.jpg",
            unitPrice: 1.20,
            tags: [.fruit],
            recipeIdeas: ["Broiled grapefruit with honey", "Grapefruit and avocado salad", "Grapefruit granita"],
            popularity: 0.45
        ),
        Product(
            id: "mandarins",
            name: "Mandarins",
            description: "Small, easy-to-peel citrus fruit with sweet segments, a popular snack straight out of hand.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/10/Citrus_reticulata_April_2013_Nordbaden.JPG",
            unitPrice: 0.70,
            tags: [.fruit],
            recipeIdeas: ["Mandarin and almond salad", "Candied mandarin peel", "Mandarin sorbet"],
            popularity: 0.6
        ),
        Product(
            id: "strawberries",
            name: "Strawberries",
            description: "Bright red, juicy berries with a fragrant sweetness, delicious fresh or baked into desserts.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Garden_strawberry_%28Fragaria_%C3%97_ananassa%29_single2.jpg/3840px-Garden_strawberry_%28Fragaria_%C3%97_ananassa%29_single2.jpg",
            unitPrice: 3.50,
            tags: [.fruit],
            recipeIdeas: ["Strawberry shortcake", "Strawberry jam", "Balsamic strawberry salad"],
            popularity: 0.85
        ),
        Product(
            id: "blueberries",
            name: "Blueberries",
            description: "Small, deep-blue berries with a sweet-tart pop, popular in baking and eaten by the handful.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/15/Blueberries.jpg",
            unitPrice: 4.50,
            tags: [.fruit],
            recipeIdeas: ["Blueberry muffins", "Blueberry pancakes", "Blueberry compote"],
            popularity: 0.8
        ),
        Product(
            id: "raspberries",
            name: "Raspberries",
            description: "Delicate, hollow-core berries with a tart-sweet flavor, best enjoyed fresh or turned into sauces and jams.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Raspberry_-_halved_%28Rubus_idaeus%29.jpg/3840px-Raspberry_-_halved_%28Rubus_idaeus%29.jpg",
            unitPrice: 4.80,
            tags: [.fruit],
            recipeIdeas: ["Raspberry coulis", "Raspberry ripple ice cream", "Raspberry almond tart"],
            popularity: 0.6
        ),
        Product(
            id: "blackberries",
            name: "Blackberries",
            description: "Glossy, deep-purple aggregate berries with a rich, slightly tart flavor.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/78/Ripe%2C_ripening%2C_and_green_blackberries.jpg",
            unitPrice: 4.20,
            tags: [.fruit],
            recipeIdeas: ["Blackberry and apple crumble", "Blackberry jam", "Blackberry sage lemonade"],
            popularity: 0.55
        ),
        Product(
            id: "bananas",
            name: "Bananas",
            description: "A soft, sweet, portable fruit with a creamy texture, eaten fresh or baked into breads and desserts.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/de/Bananavarieties.jpg",
            unitPrice: 0.40,
            tags: [.fruit],
            recipeIdeas: ["Classic banana bread", "Banana smoothie", "Caramelized bananas"],
            popularity: 0.98
        ),
        Product(
            id: "pineapple",
            name: "Pineapple",
            description: "A spiky-skinned tropical fruit with juicy, tangy-sweet flesh and a distinctive tropical aroma.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/74/%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg",
            unitPrice: 3.00,
            tags: [.fruit],
            recipeIdeas: ["Grilled pineapple skewers", "Pineapple fried rice", "Pineapple upside-down cake"],
            popularity: 0.7
        ),
        Product(
            id: "mango",
            name: "Mango",
            description: "A fragrant tropical fruit with sweet, fiberous, golden flesh around a large flat seed.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Mangos_-_single_and_halved.jpg/3840px-Mangos_-_single_and_halved.jpg",
            unitPrice: 2.20,
            tags: [.fruit],
            recipeIdeas: ["Mango salsa", "Mango sticky rice", "Mango lassi"],
            popularity: 0.75
        ),
        Product(
            id: "papaya",
            name: "Papaya",
            description: "A soft tropical fruit with sweet orange flesh and peppery black seeds at its core.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/84/Carica_papaya_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-029.jpg",
            unitPrice: 2.80,
            tags: [.fruit],
            recipeIdeas: ["Green papaya salad", "Papaya breakfast bowl", "Papaya and lime smoothie"],
            popularity: 0.45
        ),
        Product(
            id: "passionfruit",
            name: "Passionfruit",
            description: "A wrinkly-skinned tropical fruit filled with fragrant, tangy pulp and crunchy edible seeds.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/91/Passiflora_edulis_forma_flavicarpa.jpg",
            unitPrice: 0.90,
            tags: [.fruit],
            recipeIdeas: ["Passionfruit curd", "Passionfruit pavlova topping", "Passionfruit mojito"],
            popularity: 0.35
        ),
        Product(
            id: "lychee",
            name: "Lychee",
            description: "A small tropical fruit with a rough red rind and fragrant, floral, translucent flesh.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/46/Litchi_chinensis_fruits.JPG",
            unitPrice: 0.60,
            tags: [.fruit],
            recipeIdeas: ["Lychee sorbet", "Lychee martini", "Lychee and ginger salad"],
            popularity: 0.3
        ),
        Product(
            id: "watermelon",
            name: "Watermelon",
            description: "A large, thick-rinded fruit with crisp, sweet, extremely juicy red flesh — a warm-weather favorite.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/47/Taiwan_2009_Tainan_City_Organic_Farm_Watermelon_FRD_7962.jpg",
            unitPrice: 5.00,
            tags: [.fruit],
            recipeIdeas: ["Watermelon feta salad", "Watermelon mint agua fresca", "Grilled watermelon"],
            popularity: 0.75
        ),
        Product(
            id: "cantaloupe",
            name: "Cantaloupe",
            description: "A netted-skin melon with fragrant, salmon-orange flesh that's sweet and refreshingly juicy.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ae/Meloen_vrucht_met_bloem.jpg",
            unitPrice: 3.50,
            tags: [.fruit],
            recipeIdeas: ["Prosciutto-wrapped cantaloupe", "Cantaloupe smoothie", "Melon and mint salad"],
            popularity: 0.55
        ),
        Product(
            id: "rockmelon",
            name: "Rockmelon",
            description: "The common Australian and New Zealand name for cantaloupe — a netted-skin melon with sweet, fragrant orange flesh.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ae/Meloen_vrucht_met_bloem.jpg",
            unitPrice: 3.50,
            tags: [.fruit],
            recipeIdeas: ["Rockmelon and prosciutto bites", "Rockmelon smoothie", "Fruit salad with rockmelon and mint"],
            popularity: 0.5
        ),
        Product(
            id: "grapes",
            name: "Grapes",
            description: "Small, juicy clustered berries, sweet or tart depending on variety, eaten fresh or dried into raisins.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Grapes%2C_Rostov-on-Don%2C_Russia.jpg/3840px-Grapes%2C_Rostov-on-Don%2C_Russia.jpg",
            unitPrice: 3.80,
            tags: [.fruit],
            recipeIdeas: ["Roasted grapes with cheese", "Frozen grape snacks", "Grape and walnut salad"],
            popularity: 0.85
        ),
        Product(
            id: "figs",
            name: "Figs",
            description: "A soft, teardrop-shaped fruit with sweet, jammy flesh and hundreds of tiny edible seeds.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/2e/Ficus_carica_L%2C_1771.jpg",
            unitPrice: 0.80,
            tags: [.fruit],
            recipeIdeas: ["Fig and prosciutto flatbread", "Fig jam", "Honey-roasted figs with yogurt"],
            popularity: 0.35
        ),
        Product(
            id: "kiwifruit",
            name: "Kiwifruit",
            description: "A fuzzy-skinned fruit with bright green flesh, tiny black seeds, and a tangy-sweet flavor.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Actinidia_fruits.jpg",
            unitPrice: 0.60,
            tags: [.fruit],
            recipeIdeas: ["Kiwi and lime fruit salad", "Kiwi smoothie", "Pavlova with kiwi topping"],
            popularity: 0.6
        ),
        Product(
            id: "avocado",
            name: "Avocado",
            description: "A buttery, rich-fleshed fruit prized for its creamy texture, equally at home mashed, sliced, or blended.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/f/f2/Persea_americana_fruit_2.JPG",
            unitPrice: 1.80,
            tags: [.fruit],
            recipeIdeas: ["Classic guacamole", "Avocado toast", "Creamy avocado pasta sauce"],
            popularity: 0.9
        ),

        // MARK: - Dairy

        Product(
            id: "full-cream-milk",
            name: "Full cream milk",
            description: "Rich, whole-fat dairy milk with a creamy texture, the everyday choice for drinking, cereal, and cooking.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Glass_of_Milk_%2833657535532%29.jpg/1280px-Glass_of_Milk_%2833657535532%29.jpg",
            unitPrice: 2.20,
            tags: [.dairy],
            recipeIdeas: ["Creamy hot chocolate", "Homemade custard", "Classic white sauce (béchamel)"],
            popularity: 0.95
        ),
        Product(
            id: "skim-milk",
            name: "Skim milk",
            description: "Milk with the fat removed, keeping the protein and calcium in a lighter, thinner drink.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/b/bf/Skim_milk_poured_into_cereal_bowl.jpg",
            unitPrice: 2.10,
            tags: [.dairy],
            recipeIdeas: ["Protein smoothie", "Light mashed potatoes", "Skim milk latte"],
            popularity: 0.70
        ),
        Product(
            id: "lactose-free-milk",
            name: "Lactose free milk",
            description: "Regular milk treated with lactase so it's easier to digest, with the same taste and nutrition.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Lactose-free_milk%2C_BKK%2C_2021-10-01.jpg/3840px-Lactose-free_milk%2C_BKK%2C_2021-10-01.jpg",
            unitPrice: 3.20,
            tags: [.dairy],
            recipeIdeas: ["Lactose-free rice pudding", "Lactose-free pancakes", "Iced coffee"],
            popularity: 0.55
        ),
        Product(
            id: "cheddar-cheese",
            name: "Cheddar cheese",
            description: "A firm, tangy cow's milk cheese that ranges from mild to sharp, equally good sliced or melted.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/18/Somerset-Cheddar.jpg",
            unitPrice: 4.50,
            tags: [.dairy],
            recipeIdeas: ["Classic grilled cheese", "Cheddar and broccoli soup", "Mac and cheese"],
            popularity: 0.85
        ),
        Product(
            id: "mozzarella-cheese",
            name: "Mozzarella cheese",
            description: "A soft, mild, stretchy cheese famous for melting smoothly over pizza and pasta bakes.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Mozzarella_di_bufala3.jpg/3840px-Mozzarella_di_bufala3.jpg",
            unitPrice: 4.20,
            tags: [.dairy],
            recipeIdeas: ["Margherita pizza", "Caprese salad", "Baked ziti"],
            popularity: 0.80
        ),
        Product(
            id: "paneer",
            name: "Paneer",
            description: "A fresh, firm, non-melting cheese popular in South Asian cooking, mild enough to soak up any spice.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/36/Panir_Paneer_Indian_cheese_fresh.jpg",
            unitPrice: 3.80,
            tags: [.dairy],
            recipeIdeas: ["Paneer tikka", "Palak paneer", "Paneer butter masala"],
            popularity: 0.50
        ),
        Product(
            id: "yakult",
            name: "Yakult",
            description: "A small bottle of fermented milk drink packed with probiotic cultures, sweet and tangy.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0e/Yakult_drink.jpg",
            unitPrice: 3.00,
            tags: [.dairy],
            recipeIdeas: ["Yakult fruit smoothie", "Yakult jelly", "Yakult soda float"],
            popularity: 0.55
        ),
        Product(
            id: "butter",
            name: "Butter",
            description: "Churned cream pressed into a rich, spreadable fat, essential for baking, sautéing, and finishing sauces.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d3/%C5%A0v%C3%A9dsk%C3%BD_kol%C3%A1%C4%8D_naruby_904_%28cropped%29.JPG",
            unitPrice: 3.50,
            tags: [.dairy],
            recipeIdeas: ["Garlic butter", "Classic shortbread", "Brown butter pasta"],
            popularity: 0.90
        ),
        Product(
            id: "yogurt",
            name: "Yogurt",
            description: "A thick, tangy cultured dairy product, delicious on its own or as a base for dips and marinades.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/b/b8/Joghurt.jpg",
            unitPrice: 2.50,
            tags: [.dairy],
            recipeIdeas: ["Greek yogurt parfait", "Cucumber yogurt dip (tzatziki)", "Yogurt marinated chicken"],
            popularity: 0.82
        ),

        // MARK: - Pantry

        Product(
            id: "bread",
            name: "Bread",
            description: "A soft, baked loaf that's the everyday base for sandwiches, toast, and sides.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/c/c7/Korb_mit_Br%C3%B6tchen.JPG",
            unitPrice: 2.80,
            tags: [.pantry],
            recipeIdeas: ["Classic sandwich", "French toast", "Garlic bread"],
            popularity: 0.97
        ),
        Product(
            id: "biscuits",
            name: "Biscuits",
            description: "Sweet, crunchy baked snacks perfect with tea or coffee, or crushed into dessert bases.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Bourbon_and_Custard_Cream.jpeg/3840px-Bourbon_and_Custard_Cream.jpeg",
            unitPrice: 2.20,
            tags: [.pantry],
            recipeIdeas: ["Biscuit cheesecake base", "Biscuit pudding", "Chocolate-dipped biscuits"],
            popularity: 0.72
        ),
        Product(
            id: "coke",
            name: "Coke",
            description: "A classic carbonated cola soft drink, sweet and fizzy, best served ice cold.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/27/Coca_Cola_Flasche_-_Original_Taste.jpg",
            unitPrice: 1.80,
            tags: [.pantry],
            recipeIdeas: ["Cola glazed ham", "Float with ice cream", "Cola barbecue sauce"],
            popularity: 0.88
        ),
        Product(
            id: "pepsi",
            name: "Pepsi",
            description: "A carbonated cola soft drink with a sweet, bold flavor, a popular alternative to classic cola.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Pepsi_2023.svg/960px-Pepsi_2023.svg.png",
            unitPrice: 1.80,
            tags: [.pantry],
            recipeIdeas: ["Pepsi float", "Pepsi glazed chicken wings", "Spiced cola punch"],
            popularity: 0.75
        ),
        Product(
            id: "water-bottle",
            name: "Water bottle",
            description: "Plain still bottled water, the simplest way to stay hydrated on the go.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/02/Stilles_Mineralwasser.jpg",
            unitPrice: 1.00,
            tags: [.pantry],
            recipeIdeas: ["Infused fruit water", "Iced herbal tea", "Sparkling lemon water base"],
            popularity: 0.85
        ),
        Product(
            id: "pasta",
            name: "Pasta",
            description: "Dried wheat pasta in your favorite shape, the pantry staple behind countless quick dinners.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/%28Pasta%29_by_David_Adam_Kess_%28pic.2%29.jpg/3840px-%28Pasta%29_by_David_Adam_Kess_%28pic.2%29.jpg",
            unitPrice: 1.60,
            tags: [.pantry],
            recipeIdeas: ["Classic spaghetti bolognese", "Garlic butter pasta", "Pasta salad"],
            popularity: 0.86
        ),
        Product(
            id: "canned-tuna",
            name: "Canned tuna",
            description: "Flaked tuna packed in a can, a quick source of protein ready straight out of the pantry.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Chicharros_en_escabeche.jpg/3840px-Chicharros_en_escabeche.jpg",
            unitPrice: 1.90,
            tags: [.pantry],
            recipeIdeas: ["Tuna salad sandwich", "Tuna pasta bake", "Tuna and sweetcorn fritters"],
            popularity: 0.65
        ),
        Product(
            id: "vegetable-oil",
            name: "Vegetable oil",
            description: "A neutral, all-purpose cooking oil for frying, roasting, and baking.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/49/Olive_oil_from_Oneglia.jpg",
            unitPrice: 3.50,
            tags: [.pantry],
            recipeIdeas: ["Crispy fried chicken", "Stir-fried vegetables", "Homemade salad dressing"],
            popularity: 0.80
        ),
        Product(
            id: "hammer",
            name: "Hammer",
            description: "A claw hammer with a steel head and cushioned grip, for driving and pulling nails.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Stanley_graphite_claw_hammer.jpg/1280px-Stanley_graphite_claw_hammer.jpg",
            unitPrice: 18.00,
            tags: [.construction],
            recipeIdeas: [],
            popularity: 0.75
        ),
        Product(
            id: "anvil",
            name: "Anvil",
            description: "A heavy steel block with a flattened top, used as a solid work surface for hammering and shaping metal.",
            imageURL: "https://img.vevorstatic.com/us%2FGZHSBDD110LBSL3X3V0%2Fgoods_img_big-v9%2Fanvil-blacksmith-m100-1.2.jpg?timestamp=1744081843000&format=webp&format=webp",
            unitPrice: 150.00,
            tags: [.construction],
            recipeIdeas: [],
            popularity: 0.30
        ),
        Product(
            id: "screwdriver",
            name: "Screwdriver",
            description: "A cushion-grip screwdriver for turning screws, sold as a set of common flathead and Phillips tips.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Craftsman_cushion_grip_screwdrivers.jpg/1280px-Craftsman_cushion_grip_screwdrivers.jpg",
            unitPrice: 9.50,
            tags: [.construction],
            recipeIdeas: [],
            popularity: 0.78
        ),
        Product(
            id: "nails",
            name: "Nails",
            description: "A box of steel nails for general woodworking and construction fastening.",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/8e/Nails.jpg",
            unitPrice: 4.50,
            tags: [.construction],
            recipeIdeas: [],
            popularity: 0.70
        ),
    ]
}
