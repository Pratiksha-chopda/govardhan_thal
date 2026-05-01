/**
 * Govardhan Thal — 100-Item Production Seed
 * Run: node backend/seed.js  OR  npm run seed (from backend/)
 *
 * 100 authentic Gujarati/Indian items across 9 categories.
 * All items are 100% vegetarian (isVeg: true).
 * Images: dynamic source.unsplash.com keyword URLs — always match the dish.
 * SGD price: computed via virtual (1 INR = 0.016 SGD).
 */
require('dotenv').config({ path: __dirname + '/.env' });
const mongoose = require('mongoose');
const Menu     = require('./models/Menu');

const FALLBACK = 'https://upload.wikimedia.org/wikipedia/commons/6/65/Indian_food.jpg';
const u = (keywords) => `https://source.unsplash.com/600x400/?${keywords}`;

const menuItems = [

  // ══════════════════════════════════════════════
  //  THALI (8)
  // ══════════════════════════════════════════════
  {
    name:'Gujarati Thali', category:'Thali', price:299,
    description:'Complete traditional Gujarati Thali — dal, kadhi, 2 sabji, rotli, rice, chaas, pickle, papad, and mithai. The full Gujarati experience on one plate.',
    imageUrl: u('gujarati,thali,indian'), imageKeyword:'gujarati,thali,indian',
    rating:4.9, isPopular:true, isRecommended:true, isTodaySpecial:true,
  },
  {
    name:'Kathiyawadi Thali', category:'Thali', price:349,
    description:'Rustic Saurashtra-style Thali — spicy ringna bataka, sev tameta, bajra rotla, kadhi, chaas, and jaggery. Bold, smoky flavours from the heartland of Gujarat.',
    imageUrl: u('thali,gujarati,meal'), imageKeyword:'thali,gujarati,meal',
    rating:4.8, isPopular:false, isRecommended:true,
  },
  {
    name:'Mini Thali', category:'Thali', price:199,
    description:'Lighter version of our signature Thali — dal, one sabji, rotli, rice, and chaas. Perfect for a quick satisfying lunch.',
    imageUrl: u('indian,thali,lunch'), imageKeyword:'indian,thali,lunch',
    rating:4.5, isPopular:false,
  },
  {
    name:'Rajasthani Thali', category:'Thali', price:329,
    description:'Dal baati churma, gatte ki sabji, ker sangri, bajra rotla, chaas, and moong dal halwa. A royal Rajasthani spread.',
    imageUrl: u('rajasthani,thali,india'), imageKeyword:'rajasthani,thali,india',
    rating:4.7, isPopular:false, isRecommended:true,
  },
  {
    name:'Festival Thali', category:'Thali', price:399,
    description:'Grand festival meal — puri, aamras, 3 sabji, dal, kadhi, shrikhand, rice, papad, and pickle. Served on auspicious days.',
    imageUrl: u('festival,thali,indian,food'), imageKeyword:'festival,thali,indian,food',
    rating:4.8, isPopular:false, isRecommended:true,
  },
  {
    name:'Jain Thali', category:'Thali', price:279,
    description:'100% Jain — no onion, no garlic, no root vegetables. Includes dal, 2 sabji, rotli, rice, and chaas made with pure Jain ingredients.',
    imageUrl: u('jain,thali,vegetarian'), imageKeyword:'jain,thali,vegetarian',
    rating:4.6, isPopular:false,
  },
  {
    name:'Saurashtra Thali', category:'Thali', price:319,
    description:'Traditional coastal Saurashtra meal — undhiyu, fafda, jalebi, bajra bhakhri, chaas, and lasan ki chutney.',
    imageUrl: u('saurashtra,thali,gujarati'), imageKeyword:'saurashtra,thali,gujarati',
    rating:4.7, isPopular:false, isRecommended:true,
  },
  {
    name:'Vrat Thali', category:'Thali', price:249,
    description:'Upvas-friendly Thali with sabudana khichdi, farali pattice, rajgira rotli, dahi, and sendha namak chaas. Perfect for fasting days.',
    imageUrl: u('fasting,vrat,indian,food'), imageKeyword:'fasting,vrat,indian,food',
    rating:4.5, isPopular:false,
  },

  // ══════════════════════════════════════════════
  //  SABJI (22)
  // ══════════════════════════════════════════════
  {
    name:'Sev Tameta Nu Shaak', category:'Sabji', price:120,
    description:'Ripe tomatoes cooked with spices, topped with crispy thin sev. A Gujarati street-food classic — tangy, spicy, irresistible.',
    imageUrl: u('sev,tameta,tomato,curry'), imageKeyword:'sev,tameta,tomato,curry',
    rating:4.7, isPopular:true, isRecommended:true,
  },
  {
    name:'Paneer Butter Masala', category:'Sabji', price:180,
    description:'Soft paneer cubes in rich creamy tomato-butter gravy. The crowd favourite with a velvety, mildly spiced finish.',
    imageUrl: u('paneer,butter,masala'), imageKeyword:'paneer,butter,masala',
    rating:4.8, isPopular:true, isRecommended:true, isTodaySpecial:true,
  },
  {
    name:'Bhindi Masala', category:'Sabji', price:110,
    description:'Tender okra stir-fried with onions, tomatoes, and Gujarati spices until perfectly crispy.',
    imageUrl: u('bhindi,okra,masala'), imageKeyword:'bhindi,okra,masala',
    rating:4.5,
  },
  {
    name:'Palak Paneer', category:'Sabji', price:160,
    description:'Creamy spinach purée with fresh paneer cubes and a hint of cream. Mildly spiced and nutritious.',
    imageUrl: u('palak,paneer,spinach'), imageKeyword:'palak,paneer,spinach',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Aloo Gobi', category:'Sabji', price:100,
    description:'Potatoes and cauliflower slow-cooked with turmeric, cumin, and coriander. Classic comfort food.',
    imageUrl: u('aloo,gobi,potato,cauliflower'), imageKeyword:'aloo,gobi,potato,cauliflower',
    rating:4.3,
  },
  {
    name:'Ringna Bataka Nu Shaak', category:'Sabji', price:105,
    description:'Brinjal and potato in mildly spiced Gujarati masala. A staple thali sabji with rustic, homestyle taste.',
    imageUrl: u('brinjal,eggplant,potato,curry'), imageKeyword:'brinjal,eggplant,potato,curry',
    rating:4.4,
  },
  {
    name:'Methi Nu Shaak', category:'Sabji', price:110,
    description:'Fresh fenugreek leaves cooked with potatoes in a simple Gujarati tadka. Mildly bitter, earthy, deeply satisfying.',
    imageUrl: u('methi,fenugreek,curry,indian'), imageKeyword:'methi,fenugreek,curry,indian',
    rating:4.3,
  },
  {
    name:'Doodhi Nu Shaak', category:'Sabji', price:95,
    description:'Bottle gourd slow-cooked with tomatoes and a light Gujarati tadka. Light, digestive, and wholesome.',
    imageUrl: u('bottle,gourd,lauki,curry'), imageKeyword:'bottle,gourd,lauki,curry',
    rating:4.2,
  },
  {
    name:'Valor Papdi Nu Shaak', category:'Sabji', price:115,
    description:'Flat beans cooked in a tangy tomato-onion masala. A winter Gujarati special with earthy sweetness.',
    imageUrl: u('beans,valor,gujarati,sabji'), imageKeyword:'beans,valor,gujarati,sabji',
    rating:4.4,
  },
  {
    name:'Gajar Matar', category:'Sabji', price:110,
    description:'Carrots and peas sautéed with cumin, ginger, and warming spices. A simple, nutritious, colourful dry sabji.',
    imageUrl: u('carrot,peas,gajar,matar'), imageKeyword:'carrot,peas,gajar,matar',
    rating:4.2,
  },
  {
    name:'Shahi Paneer', category:'Sabji', price:190,
    description:'Paneer in a royal cashew-tomato gravy enriched with cream, saffron, and cardamom. Rich and indulgent.',
    imageUrl: u('shahi,paneer,cream,curry'), imageKeyword:'shahi,paneer,cream,curry',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Matar Paneer', category:'Sabji', price:170,
    description:'Green peas and paneer in a well-spiced tomato-onion gravy. A timeless North Indian classic, loved across India.',
    imageUrl: u('matar,paneer,peas,curry'), imageKeyword:'matar,paneer,peas,curry',
    rating:4.5, isRecommended:true,
  },
  {
    name:'Kadai Paneer', category:'Sabji', price:175,
    description:'Paneer and bell peppers tossed in bold kadai masala with onion and tomato. Smoky, spiced, restaurant-style.',
    imageUrl: u('kadai,paneer,bell,pepper'), imageKeyword:'kadai,paneer,bell,pepper',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Aloo Matar', category:'Sabji', price:105,
    description:'Potatoes and peas cooked in a spiced tomato gravy. Simple, filling, and endlessly comforting.',
    imageUrl: u('aloo,matar,potato,peas,curry'), imageKeyword:'aloo,matar,potato,peas,curry',
    rating:4.3,
  },
  {
    name:'Baingan Bharta', category:'Sabji', price:120,
    description:'Flame-roasted brinjal mashed with onion, tomato, and bold spices. Smoky, rustic, and deeply flavourful.',
    imageUrl: u('baingan,bharta,eggplant,roasted'), imageKeyword:'baingan,bharta,eggplant,roasted',
    rating:4.5,
  },
  {
    name:'Undhiyu', category:'Sabji', price:160,
    description:'The crown jewel of Gujarati winter cuisine — mixed vegetables and fenugreek dumplings slow-cooked upside-down with spices. Seasonal and festive.',
    imageUrl: u('undhiyu,gujarati,mixed,vegetable'), imageKeyword:'undhiyu,gujarati,mixed,vegetable',
    rating:4.8, isRecommended:true,
  },
  {
    name:'Kaju Curry', category:'Sabji', price:200,
    description:'Whole cashews in a creamy, mildly spiced onion-tomato gravy with a hint of cream. Rich and premium.',
    imageUrl: u('kaju,cashew,curry,indian'), imageKeyword:'kaju,cashew,curry,indian',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Tindora Nu Shaak', category:'Sabji', price:100,
    description:'Ivy gourd (tindora) stir-fried with mustard seeds, turmeric, and coriander. A simple Gujarati everyday favourite.',
    imageUrl: u('tindora,ivy,gourd,gujarati'), imageKeyword:'tindora,ivy,gourd,gujarati',
    rating:4.2,
  },
  {
    name:'Surti Locho', category:'Sabji', price:130,
    description:'Surat\'s famous steamed khaman variant — broken, soft, and served with onion, sev, and green chutney. A Surat street icon.',
    imageUrl: u('surti,locho,surat,snack'), imageKeyword:'surti,locho,surat,snack',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Mix Vegetable', category:'Sabji', price:130,
    description:'Seasonal vegetables simmered in a mildly spiced onion-tomato gravy. Colourful, balanced, and nutritious.',
    imageUrl: u('mix,vegetable,curry,indian'), imageKeyword:'mix,vegetable,curry,indian',
    rating:4.3,
  },
  {
    name:'Kobi Bataka Nu Shaak', category:'Sabji', price:95,
    description:'Cabbage and potato stir-fried with mustard seeds, green chilli, and turmeric. A simple Gujarati home essential.',
    imageUrl: u('cabbage,potato,stir,fry'), imageKeyword:'cabbage,potato,stir,fry',
    rating:4.1,
  },
  {
    name:'Paneer Tikka Masala', category:'Sabji', price:195,
    description:'Chargrilled paneer tikka cubes in a vibrant, smoky tomato-cream masala sauce. Restaurant showstopper.',
    imageUrl: u('paneer,tikka,masala,curry'), imageKeyword:'paneer,tikka,masala,curry',
    rating:4.7, isRecommended:true,
  },

  // ══════════════════════════════════════════════
  //  FARSAN (15)
  // ══════════════════════════════════════════════
  {
    name:'Khaman', category:'Farsan', price:80,
    description:'Steamed chickpea flour cake tempered with mustard seeds, curry leaves, and chillies, finished with coconut and coriander. Soft, spongy, melt-in-mouth.',
    imageUrl: u('khaman,dhokla,gujarati'), imageKeyword:'khaman,dhokla,gujarati',
    rating:4.8, isPopular:true, isRecommended:true,
  },
  {
    name:'Dhokla', category:'Farsan', price:75,
    description:'Fermented rice-chickpea batter steamed to a fluffy, tangy bite. Tempered with sesame seeds and green chillies. A Gujarat icon.',
    imageUrl: u('dhokla,steamed,gujarati'), imageKeyword:'dhokla,steamed,gujarati',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Fafda', category:'Farsan', price:70,
    description:'Crispy chickpea flour strips seasoned with ajwain and pepper. Served with papaya chutney and fried chilli. The classic Sunday morning snack.',
    imageUrl: u('fafda,gujarati,chickpea,snack'), imageKeyword:'fafda,gujarati,chickpea,snack',
    rating:4.6,
  },
  {
    name:'Handvo', category:'Farsan', price:90,
    description:'Baked savoury cake of fermented rice-lentil batter with bottle gourd, carrot, and sesame. Crispy outside, soft inside.',
    imageUrl: u('handvo,gujarati,baked,snack'), imageKeyword:'handvo,gujarati,baked,snack',
    rating:4.5,
  },
  {
    name:'Khandvi', category:'Farsan', price:85,
    description:'Delicate thin rolls of gram flour and buttermilk, tempered with coconut and mustard seeds. A Gujarati artisan delicacy.',
    imageUrl: u('khandvi,rolls,gujarati,snack'), imageKeyword:'khandvi,rolls,gujarati,snack',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Muthiya', category:'Farsan', price:70,
    description:'Steamed methi-wheat dumplings pan-fried until golden. Healthy, flavourful, and a Gujarati staple.',
    imageUrl: u('muthiya,methi,dumplings,gujarati'), imageKeyword:'muthiya,methi,dumplings,gujarati',
    rating:4.4,
  },
  {
    name:'Bhajiya', category:'Farsan', price:80,
    description:'Crispy gram flour fritters with onion, green chilli, and coriander. The perfect monsoon snack with masala chai.',
    imageUrl: u('bhajiya,pakora,fritters,indian'), imageKeyword:'bhajiya,pakora,fritters,indian',
    rating:4.5, isRecommended:true,
  },
  {
    name:'Sev Usal', category:'Farsan', price:90,
    description:'Spiced white peas gravy topped with crunchy sev, onion, tomato, and coriander. A beloved Gujarati street snack.',
    imageUrl: u('sev,usal,peas,chaat'), imageKeyword:'sev,usal,peas,chaat',
    rating:4.5,
  },
  {
    name:'Patra', category:'Farsan', price:85,
    description:'Colocasia leaves spread with spiced gram flour paste, rolled, steamed, and pan-fried until golden. Uniquely Gujarati.',
    imageUrl: u('patra,colocasia,gujarati,rolls'), imageKeyword:'patra,colocasia,gujarati,rolls',
    rating:4.5, isRecommended:true,
  },
  {
    name:'Dabeli', category:'Farsan', price:70,
    description:'Spiced mashed potato stuffed in a pav, topped with pomegranate, peanuts, and sev. The iconic Kutchi street burger.',
    imageUrl: u('dabeli,kutchi,street,food'), imageKeyword:'dabeli,kutchi,street,food',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Ragda Pattice', category:'Farsan', price:100,
    description:'Crispy potato patties smothered in spiced white peas ragda, chutneys, and sev. The ultimate Mumbai-Gujarati chaat.',
    imageUrl: u('ragda,pattice,chaat,indian'), imageKeyword:'ragda,pattice,chaat,indian',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Pani Puri', category:'Farsan', price:60,
    description:'Crispy hollow puris filled with spiced potato-chickpea filling and dunked in tangy mint-tamarind water. The ultimate street snack.',
    imageUrl: u('pani,puri,golgappa,street,food'), imageKeyword:'pani,puri,golgappa,street,food',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Bhel Puri', category:'Farsan', price:65,
    description:'Puffed rice tossed with tomato, onion, coriander, sev, and tangy chutneys. Light, crunchy, and addictive.',
    imageUrl: u('bhel,puri,chaat,puffed,rice'), imageKeyword:'bhel,puri,chaat,puffed,rice',
    rating:4.5,
  },
  {
    name:'Sev Puri', category:'Farsan', price:70,
    description:'Crispy puris topped with potato, onion, tomato, sweet-tangy chutney, and a generous crown of fine sev.',
    imageUrl: u('sev,puri,chaat,street,food'), imageKeyword:'sev,puri,chaat,street,food',
    rating:4.5,
  },
  {
    name:'Chakli', category:'Farsan', price:60,
    description:'Crunchy spiral-shaped snack made from rice flour and spices, deep-fried until golden. Festive Gujarati tea-time classic.',
    imageUrl: u('chakli,murukku,spiral,snack'), imageKeyword:'chakli,murukku,spiral,snack',
    rating:4.3,
  },

  // ══════════════════════════════════════════════
  //  SWEETS (15)
  // ══════════════════════════════════════════════
  {
    name:'Aamras', category:'Sweets', price:90,
    description:'Thick, luscious Alphonso mango pulp — chilled and served pure with a hint of cardamom. The crown jewel of a Gujarati summer thali.',
    imageUrl: u('aamras,mango,pulp,dessert'), imageKeyword:'aamras,mango,pulp,dessert',
    rating:4.9, isPopular:true, isRecommended:true, isTodaySpecial:true,
  },
  {
    name:'Shrikhand', category:'Sweets', price:80,
    description:'Strained yogurt whipped with sugar, saffron, and cardamom, garnished with pistachios and almonds. Silky, rich, and perfectly sweet.',
    imageUrl: u('shrikhand,yogurt,saffron,dessert'), imageKeyword:'shrikhand,yogurt,saffron,dessert',
    rating:4.8, isRecommended:true, isTodaySpecial:true,
  },
  {
    name:'Gulab Jamun', category:'Sweets', price:70,
    description:'Soft milk-solid dumplings deep-fried golden and soaked in rose-cardamom sugar syrup. Served warm.',
    imageUrl: u('gulab,jamun,sweet,syrup'), imageKeyword:'gulab,jamun,sweet,syrup',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Mohanthal', category:'Sweets', price:85,
    description:'Traditional Gujarati fudge from coarse gram flour, ghee, and sugar, flavoured with cardamom. Dense, fragrant, and festive.',
    imageUrl: u('mohanthal,gujarati,sweet,fudge'), imageKeyword:'mohanthal,gujarati,sweet,fudge',
    rating:4.6,
  },
  {
    name:'Basundi', category:'Sweets', price:95,
    description:'Rich reduced-milk dessert simmered with sugar, saffron, and cardamom. Garnished with pistachios. Best served chilled.',
    imageUrl: u('basundi,milk,dessert,indian'), imageKeyword:'basundi,milk,dessert,indian',
    rating:4.7, isRecommended:true, isTodaySpecial:true,
  },
  {
    name:'Jalebi', category:'Sweets', price:65,
    description:'Crispy, pretzel-shaped deep-fried batter soaked in saffron sugar syrup. Crunchy outside, syrupy inside. A timeless Indian sweet.',
    imageUrl: u('jalebi,indian,sweet,crispy'), imageKeyword:'jalebi,indian,sweet,crispy',
    rating:4.7, isPopular:true, isRecommended:true,
  },
  {
    name:'Sukhdi', category:'Sweets', price:60,
    description:'Simple Gujarati sweet made from wheat flour, ghee, and jaggery. Earthy, caramel-like, and deeply comforting.',
    imageUrl: u('sukhdi,gujarati,wheat,sweet'), imageKeyword:'sukhdi,gujarati,wheat,sweet',
    rating:4.4,
  },
  {
    name:'Ghevar', category:'Sweets', price:90,
    description:'Rajasthani disc-shaped sweet made from ghee-batter deep-fried into a honeycomb, soaked in sugar syrup and topped with rabdi.',
    imageUrl: u('ghevar,rajasthani,sweet,dessert'), imageKeyword:'ghevar,rajasthani,sweet,dessert',
    rating:4.5,
  },
  {
    name:'Ladoo', category:'Sweets', price:60,
    description:'Classic besan ladoo made from roasted gram flour, ghee, and sugar with cardamom. Festive and irresistible.',
    imageUrl: u('ladoo,besan,sweet,indian'), imageKeyword:'ladoo,besan,sweet,indian',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Barfi', category:'Sweets', price:70,
    description:'Dense milk-solid sweet cut into diamond shapes, flavoured with cardamom, and garnished with silver vark and pistachios.',
    imageUrl: u('barfi,milk,sweet,indian'), imageKeyword:'barfi,milk,sweet,indian',
    rating:4.5,
  },
  {
    name:'Rabdi', category:'Sweets', price:85,
    description:'Slow-simmered condensed milk with layers of malai, sugar, saffron, and rose water. Rich, creamy, and festive.',
    imageUrl: u('rabdi,khoya,milk,dessert'), imageKeyword:'rabdi,khoya,milk,dessert',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Kheer', category:'Sweets', price:75,
    description:'Creamy rice pudding slow-cooked in milk with sugar, cardamom, and saffron, garnished with raisins and nuts.',
    imageUrl: u('kheer,rice,pudding,indian'), imageKeyword:'kheer,rice,pudding,indian',
    rating:4.5,
  },
  {
    name:'Halwa', category:'Sweets', price:75,
    description:'Ghee-roasted semolina halwa with sugar, cardamom, and saffron. Warm, fragrant, and deeply nourishing.',
    imageUrl: u('halwa,sooji,semolina,sweet'), imageKeyword:'halwa,sooji,semolina,sweet',
    rating:4.4,
  },
  {
    name:'Peda', category:'Sweets', price:60,
    description:'Soft milk-solid sweets flavoured with cardamom and saffron. Pressed into rounds and garnished with pistachio.',
    imageUrl: u('peda,milk,sweet,indian'), imageKeyword:'peda,milk,sweet,indian',
    rating:4.4,
  },
  {
    name:'Sutar Feni', category:'Sweets', price:70,
    description:'Gossamer-thin strands of deep-fried dough sweetened with sugar. Surat\'s iconic festive sweet — melt-in-mouth delicacy.',
    imageUrl: u('feni,sutar,gujarati,sweet'), imageKeyword:'feni,sutar,gujarati,sweet',
    rating:4.5,
  },

  // ══════════════════════════════════════════════
  //  DAL (10)
  // ══════════════════════════════════════════════
  {
    name:'Gujarati Dal', category:'Dal', price:80,
    description:'Sweet and tangy toor dal tempered with mustard, curry leaves, and a touch of jaggery and tamarind. The soul of a Gujarati meal.',
    imageUrl: u('gujarati,dal,lentil,soup'), imageKeyword:'gujarati,dal,lentil,soup',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Kadhi', category:'Dal', price:75,
    description:'Silky yogurt-chickpea flour curry tempered with ghee, mustard, and curry leaves. Mildly sweet, subtly spiced.',
    imageUrl: u('kadhi,yogurt,curry,indian'), imageKeyword:'kadhi,yogurt,curry,indian',
    rating:4.6,
  },
  {
    name:'Dal Tadka', category:'Dal', price:90,
    description:'Yellow lentils slow-cooked with tomato and onion, finished with a fiery ghee tadka of cumin, garlic, and kashmiri chilli.',
    imageUrl: u('dal,tadka,lentil,indian'), imageKeyword:'dal,tadka,lentil,indian',
    rating:4.5,
  },
  {
    name:'Dal Makhani', category:'Dal', price:120,
    description:'Black urad dal and kidney beans slow-cooked overnight with butter and cream until silky-smooth. A North Indian masterpiece.',
    imageUrl: u('dal,makhani,black,lentil'), imageKeyword:'dal,makhani,black,lentil',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Panchkuti Dal', category:'Dal', price:95,
    description:'Five lentils blended and tempered with ghee, cumin, and hing. Wholesome, protein-rich, and deeply satisfying.',
    imageUrl: u('dal,five,lentil,mixed,indian'), imageKeyword:'dal,five,lentil,mixed,indian',
    rating:4.5,
  },
  {
    name:'Moong Dal', category:'Dal', price:80,
    description:'Split green mung beans tempered with mustard, curry leaves, and a hint of ginger. Light, digestive, and nourishing.',
    imageUrl: u('moong,dal,mung,bean,soup'), imageKeyword:'moong,dal,mung,bean,soup',
    rating:4.4,
  },
  {
    name:'Toor Dal', category:'Dal', price:75,
    description:'Simple, comforting pressure-cooked pigeon pea dal with a light tadka of mustard and dried red chilli.',
    imageUrl: u('toor,dal,pigeon,pea,soup'), imageKeyword:'toor,dal,pigeon,pea,soup',
    rating:4.3,
  },
  {
    name:'Dal Dhokli', category:'Dal', price:100,
    description:'Whole wheat dumpling strips simmered in sweet-tangy Gujarati dal. A one-pot comfort meal unique to Gujarat.',
    imageUrl: u('dal,dhokli,gujarati,wheat,dal'), imageKeyword:'dal,dhokli,gujarati,wheat,dal',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Chana Dal', category:'Dal', price:80,
    description:'Split chickpea dal tempered with asafoetida, ginger, and coriander. Earthy, protein-rich, and full of texture.',
    imageUrl: u('chana,dal,chickpea,lentil'), imageKeyword:'chana,dal,chickpea,lentil',
    rating:4.3,
  },
  {
    name:'Masoor Dal', category:'Dal', price:80,
    description:'Red lentil dal cooked with tomatoes and finished with a garlicky ghee tadka. Quick to prepare, deeply flavourful.',
    imageUrl: u('masoor,red,lentil,dal'), imageKeyword:'masoor,red,lentil,dal',
    rating:4.3,
  },

  // ══════════════════════════════════════════════
  //  RICE (10)
  // ══════════════════════════════════════════════
  {
    name:'Jeera Rice', category:'Rice', price:90,
    description:'Fragrant basmati rice tempered with whole cumin seeds and ghee. Light, fluffy, and the perfect base for any curry.',
    imageUrl: u('jeera,rice,cumin,basmati'), imageKeyword:'jeera,rice,cumin,basmati',
    rating:4.5,
  },
  {
    name:'Veg Pulao', category:'Rice', price:130,
    description:'Aromatic basmati rice cooked with seasonal vegetables, whole spices, and saffron. Colourful, hearty, and a meal in itself.',
    imageUrl: u('veg,pulao,rice,indian'), imageKeyword:'veg,pulao,rice,indian',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Plain Steamed Rice', category:'Rice', price:60,
    description:'Simple, perfectly cooked white rice — the most essential companion to Gujarati dal and kadhi.',
    imageUrl: u('steamed,white,rice,plain'), imageKeyword:'steamed,white,rice,plain',
    rating:4.2,
  },
  {
    name:'Masala Khichdi', category:'Rice', price:110,
    description:'One-pot comfort food — rice and moong dal cooked with ghee, cumin, turmeric, and seasonal vegetables.',
    imageUrl: u('khichdi,rice,dal,comfort'), imageKeyword:'khichdi,rice,dal,comfort',
    rating:4.5,
  },
  {
    name:'Curd Rice', category:'Rice', price:100,
    description:'Soft cooked rice mixed with fresh curd, tempered with mustard, curry leaves, and ginger. Cool, tangy, and soothing.',
    imageUrl: u('curd,rice,yogurt,south,indian'), imageKeyword:'curd,rice,yogurt,south,indian',
    rating:4.4,
  },
  {
    name:'Lemon Rice', category:'Rice', price:95,
    description:'Cooked rice tossed with lemon juice, turmeric, roasted peanuts, and curry leaves. Bright, tangy, and aromatic.',
    imageUrl: u('lemon,rice,indian,tangy'), imageKeyword:'lemon,rice,indian,tangy',
    rating:4.4,
  },
  {
    name:'Peas Pulao', category:'Rice', price:110,
    description:'Basmati rice cooked with green peas, whole spices, and a saffron infusion. Simple, fragrant, and vibrant.',
    imageUrl: u('peas,pulao,matar,rice'), imageKeyword:'peas,pulao,matar,rice',
    rating:4.3,
  },
  {
    name:'Vangi Bhath', category:'Rice', price:120,
    description:'Spiced brinjal rice — a Karnataka-style dish of basmati cooked with baby eggplant and a fragrant spice blend.',
    imageUrl: u('vangi,bhat,brinjal,rice'), imageKeyword:'vangi,bhat,brinjal,rice',
    rating:4.4,
  },
  {
    name:'Sabudana Khichdi', category:'Rice', price:100,
    description:'Tapioca pearls sautéed with peanuts, green chilli, cumin, and lemon. Light, gluten-free, and a Gujarati fasting favourite.',
    imageUrl: u('sabudana,khichdi,tapioca,pearls'), imageKeyword:'sabudana,khichdi,tapioca,pearls',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Biryani (Veg)', category:'Rice', price:160,
    description:'Dum-cooked basmati rice layered with spiced vegetables, caramelised onion, saffron milk, and fried nuts.',
    imageUrl: u('veg,biryani,basmati,dum'), imageKeyword:'veg,biryani,basmati,dum',
    rating:4.6, isRecommended:true,
  },

  // ══════════════════════════════════════════════
  //  ROTI (10)
  // ══════════════════════════════════════════════
  {
    name:'Rotli', category:'Roti', price:15,
    description:'Thin hand-rolled whole wheat flatbread cooked on an open flame until it puffs. Applied with ghee — the quintessential Gujarati bread.',
    imageUrl: u('rotli,roti,chapati,flatbread'), imageKeyword:'rotli,roti,chapati,flatbread',
    rating:4.5,
  },
  {
    name:'Thepla', category:'Roti', price:25,
    description:'Spiced flatbread with whole wheat flour, fenugreek leaves, yogurt, and turmeric. Soft, flavourful, perfect as a snack.',
    imageUrl: u('thepla,gujarati,flatbread,methi'), imageKeyword:'thepla,gujarati,flatbread,methi',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Paratha', category:'Roti', price:35,
    description:'Flaky, layered whole wheat flatbread pan-fried in ghee until golden. Served with fresh pickle and yogurt.',
    imageUrl: u('paratha,flatbread,indian,ghee'), imageKeyword:'paratha,flatbread,indian,ghee',
    rating:4.6,
  },
  {
    name:'Bajra Rotla', category:'Roti', price:20,
    description:'Traditional millet flatbread from Kathiyawad — coarsely textured, nutty-flavoured, eaten with white butter and jaggery.',
    imageUrl: u('bajra,rotla,millet,flatbread'), imageKeyword:'bajra,rotla,millet,flatbread',
    rating:4.4,
  },
  {
    name:'Puri', category:'Roti', price:20,
    description:'Deep-fried whole wheat bread that puffs golden. Served as part of the thali or with aamras during festive occasions.',
    imageUrl: u('puri,poori,fried,bread,indian'), imageKeyword:'puri,poori,fried,bread,indian',
    rating:4.5,
  },
  {
    name:'Bhakhri', category:'Roti', price:20,
    description:'Crispy, thick whole wheat flatbread — the Gujarati alternative to a cracker. Eaten with ghee, dal, or shaak.',
    imageUrl: u('bhakhri,gujarati,crispy,flatbread'), imageKeyword:'bhakhri,gujarati,crispy,flatbread',
    rating:4.3,
  },
  {
    name:'Naan', category:'Roti', price:30,
    description:'Soft, pillowy leavened bread baked in a tandoor. Lightly charred, brushed with butter or garlic-herb finish.',
    imageUrl: u('naan,tandoor,bread,indian'), imageKeyword:'naan,tandoor,bread,indian',
    rating:4.5,
  },
  {
    name:'Missi Roti', category:'Roti', price:25,
    description:'Spiced flatbread made with whole wheat and gram flour, enhanced with carom seeds and fresh coriander.',
    imageUrl: u('missi,roti,besan,flatbread'), imageKeyword:'missi,roti,besan,flatbread',
    rating:4.3,
  },
  {
    name:'Stuffed Aloo Paratha', category:'Roti', price:45,
    description:'Whole wheat paratha stuffed with spiced mashed potato, pan-fried in ghee. Served with dahi and pickle. A hearty Punjabi classic.',
    imageUrl: u('aloo,paratha,stuffed,potato'), imageKeyword:'aloo,paratha,stuffed,potato',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Methi Paratha', category:'Roti', price:35,
    description:'Whole wheat paratha enriched with fresh fenugreek leaves, carom seeds, and a hint of green chilli. Earthy and flavourful.',
    imageUrl: u('methi,paratha,fenugreek,flatbread'), imageKeyword:'methi,paratha,fenugreek,flatbread',
    rating:4.4,
  },

  // ══════════════════════════════════════════════
  //  BEVERAGES (10)
  // ══════════════════════════════════════════════
  {
    name:'Chaas', category:'Beverages', price:40,
    description:'Thin spiced buttermilk churned with cumin, ginger, salt, and coriander. The ultimate Gujarati digestive — cooling and refreshing.',
    imageUrl: u('chaas,buttermilk,drink,indian'), imageKeyword:'chaas,buttermilk,drink,indian',
    rating:4.7, isRecommended:true,
  },
  {
    name:'Lassi', category:'Beverages', price:70,
    description:'Thick creamy yogurt drink blended with sugar and rose water. Rich, chilled, and deeply satisfying.',
    imageUrl: u('lassi,yogurt,drink,indian'), imageKeyword:'lassi,yogurt,drink,indian',
    rating:4.8, isRecommended:true,
  },
  {
    name:'Masala Chai', category:'Beverages', price:30,
    description:'Robust Gujarati-style tea brewed with ginger, cardamom, cinnamon, and black pepper, simmered with full-fat milk.',
    imageUrl: u('masala,chai,tea,spiced'), imageKeyword:'masala,chai,tea,spiced',
    rating:4.7,
  },
  {
    name:'Mango Lassi', category:'Beverages', price:85,
    description:'Creamy Alphonso mango pulp blended with thick yogurt and a pinch of cardamom. A fruity, indulgent summer special.',
    imageUrl: u('mango,lassi,drink,yellow'), imageKeyword:'mango,lassi,drink,yellow',
    rating:4.8, isRecommended:true,
  },
  {
    name:'Fresh Lime Soda', category:'Beverages', price:40,
    description:'Chilled sparkling water with freshly squeezed lime, black salt, and chaat masala. The perfect light refresher.',
    imageUrl: u('lime,soda,fresh,drink'), imageKeyword:'lime,soda,fresh,drink',
    rating:4.4,
  },
  {
    name:'Rose Milk', category:'Beverages', price:60,
    description:'Chilled full-fat milk blended with fragrant rose syrup and a dusting of cardamom. Floral, sweet, and cooling.',
    imageUrl: u('rose,milk,pink,drink'), imageKeyword:'rose,milk,pink,drink',
    rating:4.5,
  },
  {
    name:'Thandai', category:'Beverages', price:80,
    description:'Festive chilled milk blended with nuts, seeds, saffron, rose petals, and cardamom. Rich, cooling, and celebratory.',
    imageUrl: u('thandai,holi,milk,nuts,drink'), imageKeyword:'thandai,holi,milk,nuts,drink',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Aam Panna', category:'Beverages', price:50,
    description:'Refreshing raw mango cooler blended with mint, cumin, black salt, and jaggery. The perfect summer antidote.',
    imageUrl: u('aam,panna,raw,mango,drink'), imageKeyword:'aam,panna,raw,mango,drink',
    rating:4.6, isRecommended:true,
  },
  {
    name:'Jaljeera', category:'Beverages', price:40,
    description:'Tangy and spiced jeera-based cold drink with lemon, mint, and black salt. A digestive and refreshing appetiser drink.',
    imageUrl: u('jaljeera,cumin,spiced,drink'), imageKeyword:'jaljeera,cumin,spiced,drink',
    rating:4.3,
  },
  {
    name:'Filter Coffee', category:'Beverages', price:35,
    description:'Strong South Indian filter decoction mixed with hot frothed milk. Served in traditional dabarah-tumbler style.',
    imageUrl: u('filter,coffee,south,indian'), imageKeyword:'filter,coffee,south,indian',
    rating:4.5,
  },

  // ══════════════════════════════════════════════
  //  EXTRAS (10)
  // ══════════════════════════════════════════════
  {
    name:'Papad', category:'Extras', price:20,
    description:'Crispy sun-dried urad dal wafers roasted or fried until perfectly crunchy. A thali essential.',
    imageUrl: u('papad,poppadom,crispy,indian'), imageKeyword:'papad,poppadom,crispy,indian',
    rating:4.3,
  },
  {
    name:'Kachumber Salad', category:'Extras', price:35,
    description:'Diced cucumber, tomato, and onion tossed with lemon, green chilli, and coriander. Light, crunchy, and cooling.',
    imageUrl: u('kachumber,salad,cucumber,fresh'), imageKeyword:'kachumber,salad,cucumber,fresh',
    rating:4.2,
  },
  {
    name:'Mixed Pickle', category:'Extras', price:25,
    description:'Homemade Gujarati-style pickle of raw mango, carrot, and lime, slow-cured in mustard oil and spices.',
    imageUrl: u('pickle,achar,mixed,indian'), imageKeyword:'pickle,achar,mixed,indian',
    rating:4.4,
  },
  {
    name:'Ghee (Extra)', category:'Extras', price:20,
    description:'Pure clarified butter — the finishing touch that transforms every rotli, dal, and khichdi into something extraordinary.',
    imageUrl: u('ghee,clarified,butter,golden'), imageKeyword:'ghee,clarified,butter,golden',
    rating:4.6,
  },
  {
    name:'Dahi (Curd)', category:'Extras', price:30,
    description:'Fresh thick set yogurt — naturally sour, cooling, and probiotic-rich. The perfect foil to any spicy dish.',
    imageUrl: u('dahi,curd,yogurt,white'), imageKeyword:'dahi,curd,yogurt,white',
    rating:4.4,
  },
  {
    name:'Raita', category:'Extras', price:35,
    description:'Whisked yogurt with cucumber, roasted cumin, and mint. Cool, tangy, and the ideal companion for rice or paratha.',
    imageUrl: u('raita,cucumber,yogurt,dip'), imageKeyword:'raita,cucumber,yogurt,dip',
    rating:4.4,
  },
  {
    name:'Mukhwas', category:'Extras', price:15,
    description:'Colourful fennel seed and mukhwas mix — the traditional post-meal mouth freshener and digestive. Complimentary with every thali.',
    imageUrl: u('mukhwas,fennel,mouth,freshener'), imageKeyword:'mukhwas,fennel,mouth,freshener',
    rating:4.2,
  },
  {
    name:'Gor Keri Athanu', category:'Extras', price:30,
    description:'Sweet and spicy raw mango pickle slow-cured in jaggery and spices. A quintessential Gujarati accompaniment.',
    imageUrl: u('mango,pickle,sweet,gujarati'), imageKeyword:'mango,pickle,sweet,gujarati',
    rating:4.5,
  },
  {
    name:'Green Chutney', category:'Extras', price:20,
    description:'Fresh coriander-mint chutney blended with lemon, green chilli, and garlic. The essential dipping sauce for all farsan.',
    imageUrl: u('green,chutney,coriander,mint'), imageKeyword:'green,chutney,coriander,mint',
    rating:4.5, isRecommended:true,
  },
  {
    name:'Tamarind Chutney', category:'Extras', price:20,
    description:'Sweet and tangy tamarind sauce with jaggery, cumin, and dried ginger. Indispensable chaat topping and dip.',
    imageUrl: u('tamarind,chutney,sweet,sour'), imageKeyword:'tamarind,chutney,sweet,sour',
    rating:4.5,
  },
];

// ─── Seeder ───────────────────────────────────────────────────────────────────
const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅  MongoDB connected');

    const deleted = await Menu.deleteMany({});
    console.log(`🗑️   Cleared ${deleted.deletedCount} existing menu items`);

    // Apply mandatory defaults to every item:
    //   • isVeg: true      — 100% vegetarian restaurant
    //   • isAvailable: true — all items available by default
    const enriched = menuItems.map((item) => ({
      isVeg:       true,
      isAvailable: true,
      isPopular:      false,
      isRecommended:  false,
      isTodaySpecial: false,
      ...item,                  // item fields override defaults where explicitly set
    }));

    const inserted = await Menu.insertMany(enriched);
    console.log(`\n🌱  Successfully seeded ${inserted.length} menu items:\n`);

    // ── Summary by category
    const summary = {};
    inserted.forEach((item) => { summary[item.category] = (summary[item.category] || 0) + 1; });
    Object.entries(summary)
      .sort(([a], [b]) => a.localeCompare(b))
      .forEach(([cat, count]) => console.log(`   ${cat.padEnd(12)} → ${count} items`));

    console.log(`\n✅  Popular        : ${inserted.filter(i => i.isPopular).length}`);
    console.log(`✅  Today Specials : ${inserted.filter(i => i.isTodaySpecial).length}`);
    console.log(`✅  Recommended    : ${inserted.filter(i => i.isRecommended).length}`);
    console.log(`✅  Vegetarian     : ${inserted.filter(i => i.isVeg).length} / ${inserted.length}`);
    console.log(`\n🎉  Seed complete! Total: ${inserted.length} items across ${Object.keys(summary).length} categories.\n`);
  } catch (err) {
    console.error('❌  Seed failed:', err.message);
  } finally {
    await mongoose.disconnect();
    console.log('🔌  MongoDB disconnected');
  }
};

seed();
