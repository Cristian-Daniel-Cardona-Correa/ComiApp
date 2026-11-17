import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/cooking_step.dart';

/// Catálogo de las 10 recetas iniciales de comiAPP
/// Diseñadas con pasos claros, temporizadores y datos nutricionales/dietéticos reales.
class InitialRecipes {
  InitialRecipes._();

  static List<Recipe> get recipes => [
        // 1. Pasta Carbonara Tradicional
        const Recipe(
          id: 'pasta-carbonara',
          title: 'Pasta Carbonara Tradicional',
          description:
              'La auténtica receta romana sin nata: yemas cremosas, queso pecorino, pimienta negra recién molida y panceta crujiente.',
          imageUrl:
              'https://images.unsplash.com/photo-1612874742237-6526221588e3?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 20,
          difficulty: RecipeDifficulty.medio,
          defaultPortions: 2,
          dietaryTags: ['Rápido', 'Pasta', 'Italiana', 'Clásica'],
          isVegetarian: false,
          isVegan: false,
          isGlutenFree: false,
          ingredients: [
            Ingredient(
                id: 'carb_1',
                name: 'Espaguetis',
                baseQuantity: 200,
                unit: 'g',
                category: 'Pasta'),
            Ingredient(
                id: 'carb_2',
                name: 'Panceta o tocineta gruesa en cubos',
                baseQuantity: 120,
                unit: 'g',
                category: 'Carnes'),
            Ingredient(
                id: 'carb_3',
                name: 'Yemas de huevo fresco',
                baseQuantity: 3,
                unit: 'unidades',
                category: 'Huevos'),
            Ingredient(
                id: 'carb_4',
                name: 'Queso Pecorino o Parmesano rallado',
                baseQuantity: 60,
                unit: 'g',
                category: 'Lácteos'),
            Ingredient(
                id: 'carb_5',
                name: 'Pimienta negra recién molida',
                baseQuantity: 1,
                unit: 'cdta',
                category: 'Especias'),
            Ingredient(
                id: 'carb_6',
                name: 'Sal para el agua de la pasta',
                baseQuantity: 15,
                unit: 'g',
                category: 'Condimentos'),
          ],
          steps: [
            CookingStep(
              id: 'carb_step_1',
              stepNumber: 1,
              title: 'Poner el agua a hervir',
              instruction:
                  'Pon una olla grande con abundante agua a fuego alto. Cuando rompa a hervir con fuerza, añade la sal.',
              relevantIngredientIds: ['carb_6'],
              chefTip: 'Usa 1 litro de agua por cada 100g de pasta para que no se pegue.',
            ),
            CookingStep(
              id: 'carb_step_2',
              stepNumber: 2,
              title: 'Dorar la panceta',
              instruction:
                  'En una sartén fría a fuego medio-bajo, coloca los cubos de tocineta sin aceite adicional. Deja que suelte su propia grasa hasta quedar dorada y crujiente.',
              timerMinutes: 6,
              timerLabel: 'Dorar panceta',
              relevantIngredientIds: ['carb_2'],
              chefTip: 'Apaga el fuego al terminar y reserva la grasa en la sartén.',
            ),
            CookingStep(
              id: 'carb_step_3',
              stepNumber: 3,
              title: 'Cocinar la pasta al dente',
              instruction:
                  'Agrega los espaguetis al agua hirviendo. Remueve durante los primeros 30 segundos y cocina al dente según el temporizador.',
              timerMinutes: 9,
              timerLabel: 'Hervir espaguetis',
              relevantIngredientIds: ['carb_1'],
              chefTip: 'Antes de escurrir, guarda media taza del agua de cocción con almidón.',
            ),
            CookingStep(
              id: 'carb_step_4',
              stepNumber: 4,
              title: 'Mezclar la crema de yemas',
              instruction:
                  'En un tazón hondo bate las yemas con el queso rallado y abundante pimienta negra hasta formar una pasta espesa.',
              relevantIngredientIds: ['carb_3', 'carb_4', 'carb_5'],
            ),
            CookingStep(
              id: 'carb_step_5',
              stepNumber: 5,
              title: 'Emulsionar fuera del fuego',
              instruction:
                  'Pasa la pasta caliente recién escurrida a la sartén con la panceta (con el fuego apagado). Vierte la mezcla de yemas y un chorrito de agua de pasta. Mezcla enérgicamente para lograr una salsa brillante y cremosa sin que se corte el huevo.',
              relevantIngredientIds: ['carb_1', 'carb_2', 'carb_3', 'carb_4'],
              chefTip: '¡Nunca lo hagas con fuego encendido o quedará como huevo revuelto!',
            ),
          ],
        ),

        // 2. Arroz con Pollo Casero Latino
        const Recipe(
          id: 'arroz-con-pollo',
          title: 'Arroz con Pollo Casero Latino',
          description:
              'Plato insignia lleno de sabor con pollo sazonado, sofrito criollo, verduras frescas y arroz dorado sueltito.',
          imageUrl:
              'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 45,
          difficulty: RecipeDifficulty.medio,
          defaultPortions: 4,
          dietaryTags: ['Almuerzo', 'Tradicional', 'Pollo', 'Completo'],
          isVegetarian: false,
          isVegan: false,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'acp_1',
                name: 'Pechuga o muslos de pollo picados en dados',
                baseQuantity: 500,
                unit: 'g',
                category: 'Carnes'),
            Ingredient(
                id: 'acp_2',
                name: 'Arroz blanco',
                baseQuantity: 300,
                unit: 'g',
                category: 'Granos'),
            Ingredient(
                id: 'acp_3',
                name: 'Cebolla cabezona picada fina',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'acp_4',
                name: 'Pimentón rojo en tiritas',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'acp_5',
                name: 'Dientes de ajo triturados',
                baseQuantity: 3,
                unit: 'dientes',
                category: 'Condimentos'),
            Ingredient(
                id: 'acp_6',
                name: 'Arvejas y zanahorias en cubitos',
                baseQuantity: 150,
                unit: 'g',
                category: 'Verduras'),
            Ingredient(
                id: 'acp_7',
                name: 'Caldo de pollo caliente',
                baseQuantity: 650,
                unit: 'ml',
                category: 'Líquidos'),
            Ingredient(
                id: 'acp_8',
                name: 'Color o achiote y comino',
                baseQuantity: 1,
                unit: 'cdta',
                category: 'Especias'),
          ],
          steps: [
            CookingStep(
              id: 'acp_step_1',
              stepNumber: 1,
              title: 'Sellar el pollo',
              instruction:
                  'En una olla o sartén grande con dos cucharadas de aceite caliente, sella los trozos de pollo sazonados con sal y comino hasta que doren.',
              timerMinutes: 6,
              timerLabel: 'Sellar pollo',
              relevantIngredientIds: ['acp_1', 'acp_8'],
            ),
            CookingStep(
              id: 'acp_step_2',
              stepNumber: 2,
              title: 'Hacer el sofrito criollo',
              instruction:
                  'Añade la cebolla, ajo, pimentón y achiote a la misma olla. Cocina a fuego medio revolviendo constantemente hasta que la cebolla esté transparente.',
              timerMinutes: 7,
              timerLabel: 'Sofrito criollo',
              relevantIngredientIds: ['acp_3', 'acp_4', 'acp_5', 'acp_8'],
            ),
            CookingStep(
              id: 'acp_step_3',
              stepNumber: 3,
              title: 'Nacarar el arroz y mezclar verduras',
              instruction:
                  'Incorpora el arroz sin lavar y las arvejas con zanahoria. Sofríe todo junto durante 2 minutos para que el grano absorba el sabor.',
              relevantIngredientIds: ['acp_2', 'acp_6'],
            ),
            CookingStep(
              id: 'acp_step_4',
              stepNumber: 4,
              title: 'Cocinar el arroz tapado',
              instruction:
                  'Vierte el caldo de pollo caliente. Deja que hierva a fuego alto hasta que el líquido se evapore casi todo a nivel del arroz. Luego tapa, baja al fuego mínimo y programa el temporizador.',
              timerMinutes: 20,
              timerLabel: 'Cocción arroz tapado',
              relevantIngredientIds: ['acp_7'],
              chefTip: '¡No destapes la olla durante los primeros 15 minutos para atrapar el vapor!',
            ),
          ],
        ),

        // 3. Sopa de Lentejas Casera Reconfortante
        const Recipe(
          id: 'sopa-lentejas',
          title: 'Sopa de Lentejas Casera Reconfortante',
          description:
              'Nutritiva, caliente y espesa. Con verduras salteadas, papita en cubos y un toque ahumado de comino y laurel.',
          imageUrl:
              'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 35,
          difficulty: RecipeDifficulty.facil,
          defaultPortions: 4,
          dietaryTags: ['Vegetariano', 'Vegano', 'Sin Gluten', 'Saludable', 'Económica'],
          isVegetarian: true,
          isVegan: true,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'len_1',
                name: 'Lentejas pardinas limpias',
                baseQuantity: 250,
                unit: 'g',
                category: 'Granos'),
            Ingredient(
                id: 'len_2',
                name: 'Papas medianas peladas y en cubitos',
                baseQuantity: 2,
                unit: 'unidades',
                category: 'Tubérculos'),
            Ingredient(
                id: 'len_3',
                name: 'Zanahoria grande en cubos pequeños',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'len_4',
                name: 'Tomate maduro rallado',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'len_5',
                name: 'Cebolla larga picada',
                baseQuantity: 2,
                unit: 'tallos',
                category: 'Verduras'),
            Ingredient(
                id: 'len_6',
                name: 'Agua o caldo de verduras',
                baseQuantity: 1000,
                unit: 'ml',
                category: 'Líquidos'),
            Ingredient(
                id: 'len_7',
                name: 'Hojas de laurel y comino',
                baseQuantity: 1,
                unit: 'cdta',
                category: 'Especias'),
          ],
          steps: [
            CookingStep(
              id: 'len_step_1',
              stepNumber: 1,
              title: 'Sofreír las verduras base',
              instruction:
                  'En una olla mediana añade una cucharada de aceite y sofríe la cebolla, tomate, zanahoria y comino hasta que suelten su jugo aroma.',
              timerMinutes: 5,
              timerLabel: 'Sofreír verduras',
              relevantIngredientIds: ['len_3', 'len_4', 'len_5', 'len_7'],
            ),
            CookingStep(
              id: 'len_step_2',
              stepNumber: 2,
              title: 'Añadir lentejas y líquido',
              instruction:
                  'Agrega las lentejas enjuagadas, el laurel y el agua o caldo. Sube el fuego hasta que rompa a hervir.',
              relevantIngredientIds: ['len_1', 'len_6', 'len_7'],
            ),
            CookingStep(
              id: 'len_step_3',
              stepNumber: 3,
              title: 'Cocinar lentejas a fuego medio',
              instruction:
                  'Baja el fuego a medio-bajo, tapa parcialmente y deja cocinar hasta que las lentejas comiencen a ablandar.',
              timerMinutes: 15,
              timerLabel: 'Primera cocción lentejas',
            ),
            CookingStep(
              id: 'len_step_4',
              stepNumber: 4,
              title: 'Incorporar las papas y espesar',
              instruction:
                  'Añade los cubos de papa y una pizca más de sal. Cocina hasta que la papa esté tierna y el caldo espese naturalmente.',
              timerMinutes: 12,
              timerLabel: 'Cocinar papas en sopa',
              relevantIngredientIds: ['len_2'],
              chefTip: 'Aplasta unos cuantos granos de lenteja contra la pared de la olla para una textura más cremosa.',
            ),
          ],
        ),

        // 4. Tacos de Champiñones al Pastor
        const Recipe(
          id: 'tacos-pastor-champi',
          title: 'Tacos de Champiñones al Pastor',
          description:
              'Una versión vegetariana y rápida de los reyes del taco callejero, con piña asada, cebollita y cilantro fresco.',
          imageUrl:
              'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 25,
          difficulty: RecipeDifficulty.facil,
          defaultPortions: 3,
          dietaryTags: ['Vegetariano', 'Vegano', 'Sin Gluten', 'Rápido', 'Mexicana'],
          isVegetarian: true,
          isVegan: true,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'tac_1',
                name: 'Champiñones laminados gruesos',
                baseQuantity: 400,
                unit: 'g',
                category: 'Hongos'),
            Ingredient(
                id: 'tac_2',
                name: 'Pasta de achiote disuelta en jugo de naranja',
                baseQuantity: 3,
                unit: 'cda',
                category: 'Salsas'),
            Ingredient(
                id: 'tac_3',
                name: 'Rodajas de piña fresca en triángulos',
                baseQuantity: 150,
                unit: 'g',
                category: 'Frutas'),
            Ingredient(
                id: 'tac_4',
                name: 'Tortillas de maíz',
                baseQuantity: 6,
                unit: 'unidades',
                category: 'Tortillas'),
            Ingredient(
                id: 'tac_5',
                name: 'Cebolla morada y cilantro picados',
                baseQuantity: 50,
                unit: 'g',
                category: 'Guarnición'),
            Ingredient(
                id: 'tac_6',
                name: 'Limones cortados en cuartos',
                baseQuantity: 2,
                unit: 'unidades',
                category: 'Frutas'),
          ],
          steps: [
            CookingStep(
              id: 'tac_step_1',
              stepNumber: 1,
              title: 'Marinar los champiñones',
              instruction:
                  'Baña los champiñones en la mezcla de achiote, jugo de naranja, pizca de orégano y sal. Deja reposar mientras calientas la sartén.',
              relevantIngredientIds: ['tac_1', 'tac_2'],
            ),
            CookingStep(
              id: 'tac_step_2',
              stepNumber: 2,
              title: 'Asar la piña',
              instruction:
                  'En una sartén bien caliente o comal asa los triángulos de piña hasta que tengan bordes doraditos o caramelizados.',
              timerMinutes: 4,
              timerLabel: 'Caramelizar piña',
              relevantIngredientIds: ['tac_3'],
            ),
            CookingStep(
              id: 'tac_step_3',
              stepNumber: 3,
              title: 'Saltear los champiñones al pastor',
              instruction:
                  'A fuego alto saltea los champiñones marinados hasta que doren y se reduzca el jugo.',
              timerMinutes: 6,
              timerLabel: 'Saltear champiñones',
              relevantIngredientIds: ['tac_1'],
            ),
            CookingStep(
              id: 'tac_step_4',
              stepNumber: 4,
              title: 'Armar los tacos',
              instruction:
                  'Calienta las tortillas de maíz en el comal, sirve una porción generosa de champiñones, piña asada, cebollita, cilantro y unas gotas de limón.',
              relevantIngredientIds: ['tac_3', 'tac_4', 'tac_5', 'tac_6'],
            ),
          ],
        ),

        // 5. Salmón a la Sartén con Espárragos
        const Recipe(
          id: 'salmon-esparragos',
          title: 'Salmón a la Sartén con Espárragos',
          description:
              'Cena gourmet en menos de 20 minutos: piel crujiente, centro jugoso, espárragos al dente y mantequilla con limón.',
          imageUrl:
              'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 20,
          difficulty: RecipeDifficulty.facil,
          defaultPortions: 2,
          dietaryTags: ['Rápido', 'Saludable', 'Sin Gluten', 'Gourmet', 'Pescados'],
          isVegetarian: false,
          isVegan: false,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'sal_1',
                name: 'Filetes de salmón fresco con piel',
                baseQuantity: 2,
                unit: 'unidades (180g c/u)',
                category: 'Pescados'),
            Ingredient(
                id: 'sal_2',
                name: 'Espárragos verdes limpios (sin el tallo duro)',
                baseQuantity: 200,
                unit: 'g',
                category: 'Verduras'),
            Ingredient(
                id: 'sal_3',
                name: 'Mantequilla o aceite de oliva',
                baseQuantity: 20,
                unit: 'g',
                category: 'Grasas'),
            Ingredient(
                id: 'sal_4',
                name: 'Diente de ajo laminado',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Condimentos'),
            Ingredient(
                id: 'sal_5',
                name: 'Jugo de medio limón y sal en escamas',
                baseQuantity: 1,
                unit: 'cda',
                category: 'Condimentos'),
          ],
          steps: [
            CookingStep(
              id: 'sal_step_1',
              stepNumber: 1,
              title: 'Secar y sazonar el salmón',
              instruction:
                  'Seca muy bien los filetes con papel de cocina (la clave para una piel crujiente). Sazona con sal y pimienta por ambos lados.',
              relevantIngredientIds: ['sal_1'],
            ),
            CookingStep(
              id: 'sal_step_2',
              stepNumber: 2,
              title: 'Cocinar por el lado de la piel',
              instruction:
                  'Calienta la sartén a fuego medio-alto con un chorrito de aceite. Coloca el salmón con la piel hacia abajo y presiona suavemente con la espátula los primeros 10 segundos. Cocina sin mover.',
              timerMinutes: 4,
              timerLabel: 'Piel de salmón crujiente',
              relevantIngredientIds: ['sal_1'],
            ),
            CookingStep(
              id: 'sal_step_3',
              stepNumber: 3,
              title: 'Voltear y agregar espárragos',
              instruction:
                  'Voltea el salmón. Añade los espárragos, ajo y la mantequilla a los lados de la sartén. Baña el salmón con la mantequilla derretida.',
              timerMinutes: 3,
              timerLabel: 'Dorar espárragos y salmón',
              relevantIngredientIds: ['sal_2', 'sal_3', 'sal_4'],
            ),
            CookingStep(
              id: 'sal_step_4',
              stepNumber: 4,
              title: 'Terminar con limón',
              instruction:
                  'Exprime el limón fresco sobre el pescado y los espárragos justo antes de servir.',
              relevantIngredientIds: ['sal_5'],
            ),
          ],
        ),

        // 6. Bowl Mediterráneo de Quinoa y Garbanzos
        const Recipe(
          id: 'bowl-quinoa-garbanzos',
          title: 'Bowl Mediterráneo de Quinoa y Garbanzos',
          description:
              'Fresco, colorido y cargado de proteína vegetal: garbanzos crocantes especiados, pepino, tomate cherry, aguacate y aderezo tahini.',
          imageUrl:
              'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 25,
          difficulty: RecipeDifficulty.facil,
          defaultPortions: 2,
          dietaryTags: ['Vegetariano', 'Vegano', 'Sin Gluten', 'Saludable', 'Fitness'],
          isVegetarian: true,
          isVegan: true,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'bwl_1',
                name: 'Quinoa cruda lavada',
                baseQuantity: 120,
                unit: 'g',
                category: 'Granos'),
            Ingredient(
                id: 'bwl_2',
                name: 'Garbanzos cocidos escurridos',
                baseQuantity: 200,
                unit: 'g',
                category: 'Legumbres'),
            Ingredient(
                id: 'bwl_3',
                name: 'Tomates cherry partidos por la mitad',
                baseQuantity: 100,
                unit: 'g',
                category: 'Verduras'),
            Ingredient(
                id: 'bwl_4',
                name: 'Pepino cohombro en rodajas finas',
                baseQuantity: 1,
                unit: 'unidad pequeña',
                category: 'Verduras'),
            Ingredient(
                id: 'bwl_5',
                name: 'Aguacate hass en cubos',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Frutas'),
            Ingredient(
                id: 'bwl_6',
                name: 'Aceite de oliva y pimentón ahumado (paprika)',
                baseQuantity: 2,
                unit: 'cda',
                category: 'Condimentos'),
          ],
          steps: [
            CookingStep(
              id: 'bwl_step_1',
              stepNumber: 1,
              title: 'Cocinar la quinoa',
              instruction:
                  'Pon la quinoa en una cacerola con el doble de agua (240ml) y una pizca de sal. Tapa y cocina a fuego bajo hasta que absorba el agua.',
              timerMinutes: 14,
              timerLabel: 'Hervir quinoa',
              relevantIngredientIds: ['bwl_1'],
            ),
            CookingStep(
              id: 'bwl_step_2',
              stepNumber: 2,
              title: 'Tostar los garbanzos especiados',
              instruction:
                  'En una sartén saltea los garbanzos con aceite de oliva, paprika y sal hasta que queden crujientes por fuera.',
              timerMinutes: 7,
              timerLabel: 'Garbanzos crujientes',
              relevantIngredientIds: ['bwl_2', 'bwl_6'],
            ),
            CookingStep(
              id: 'bwl_step_3',
              stepNumber: 3,
              title: 'Montar el bowl',
              instruction:
                  'Coloca una base de quinoa tibia, distribuye encima los garbanzos dorados, pepino, tomate cherry y los cubos de aguacate. Corona con un toque de aceite de oliva.',
              relevantIngredientIds: ['bwl_3', 'bwl_4', 'bwl_5'],
            ),
          ],
        ),

        // 7. Pollo en Salsa de Champiñones
        const Recipe(
          id: 'pollo-champinones',
          title: 'Pollo en Salsa de Champiñones',
          description:
              'Pechuga tierna y jugosa bañada en una sedosa salsa de champiñones frescos al ajillo y crema.',
          imageUrl:
              'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 30,
          difficulty: RecipeDifficulty.medio,
          defaultPortions: 3,
          dietaryTags: ['Almuerzo', 'Pollo', 'Clásica', 'Confort'],
          isVegetarian: false,
          isVegan: false,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'pch_1',
                name: 'Filetes de pechuga de pollo',
                baseQuantity: 500,
                unit: 'g',
                category: 'Carnes'),
            Ingredient(
                id: 'pch_2',
                name: 'Champiñones parís cortados en láminas',
                baseQuantity: 250,
                unit: 'g',
                category: 'Hongos'),
            Ingredient(
                id: 'pch_3',
                name: 'Crema de leche o nata para cocinar',
                baseQuantity: 200,
                unit: 'ml',
                category: 'Lácteos'),
            Ingredient(
                id: 'pch_4',
                name: 'Cebolla blanca finamente picada',
                baseQuantity: 1,
                unit: 'unidad pequeña',
                category: 'Verduras'),
            Ingredient(
                id: 'pch_5',
                name: 'Mantequilla y caldo de pollo',
                baseQuantity: 100,
                unit: 'ml',
                category: 'Líquidos'),
          ],
          steps: [
            CookingStep(
              id: 'pch_step_1',
              stepNumber: 1,
              title: 'Dorar las pechugas',
              instruction:
                  'Sazona el pollo con sal, ajo en polvo y pimienta. Dora los filetes en una sartén caliente con mantequilla durante 3 minutos por lado. Retira y reserva.',
              timerMinutes: 6,
              timerLabel: 'Dorar pechuga',
              relevantIngredientIds: ['pch_1'],
            ),
            CookingStep(
              id: 'pch_step_2',
              stepNumber: 2,
              title: 'Saltear cebolla y champiñones',
              instruction:
                  'En la misma sartén añade la cebolla picada y los champiñones. Saltea a fuego medio hasta que los hongos doren.',
              timerMinutes: 6,
              timerLabel: 'Saltear champiñones',
              relevantIngredientIds: ['pch_2', 'pch_4'],
            ),
            CookingStep(
              id: 'pch_step_3',
              stepNumber: 3,
              title: 'Reducir la salsa cremosa',
              instruction:
                  'Agrega el caldo y la crema de leche. Deja hervir suavemente para que la salsa espese. Regresa el pollo a la sartén por 2 minutos para que se impregne de los jugos.',
              timerMinutes: 6,
              timerLabel: 'Reducir salsa cremosa',
              relevantIngredientIds: ['pch_3', 'pch_5'],
            ),
          ],
        ),

        // 8. Shakshuka con Huevos Pochados
        const Recipe(
          id: 'shakshuka-huevos',
          title: 'Shakshuka con Huevos Pochados',
          description:
              'Huevos cocinados suavemente en una espesa salsa de tomates maduros, pimientos asados, comino y pimentón.',
          imageUrl:
              'https://images.unsplash.com/photo-1590412200988-a436970781fa?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 25,
          difficulty: RecipeDifficulty.facil,
          defaultPortions: 2,
          dietaryTags: ['Vegetariano', 'Desayuno', 'Brunch', 'Sin Gluten', 'Rápido'],
          isVegetarian: true,
          isVegan: false,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'shk_1',
                name: 'Huevos de campo',
                baseQuantity: 4,
                unit: 'unidades',
                category: 'Huevos'),
            Ingredient(
                id: 'shk_2',
                name: 'Tomates triturados o picados',
                baseQuantity: 400,
                unit: 'g',
                category: 'Verduras'),
            Ingredient(
                id: 'shk_3',
                name: 'Pimiento rojo en cubos',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'shk_4',
                name: 'Cebolla cabezona picada',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'shk_5',
                name: 'Comino, pimentón dulce y sal',
                baseQuantity: 1,
                unit: 'cda',
                category: 'Especias'),
          ],
          steps: [
            CookingStep(
              id: 'shk_step_1',
              stepNumber: 1,
              title: 'Sofreír la base de verduras',
              instruction:
                  'Calienta aceite de oliva en una sartén honda. Cocina la cebolla y el pimiento hasta que estén muy tiernos.',
              timerMinutes: 7,
              timerLabel: 'Pochar cebolla y pimiento',
              relevantIngredientIds: ['shk_3', 'shk_4'],
            ),
            CookingStep(
              id: 'shk_step_2',
              stepNumber: 2,
              title: 'Cocinar la salsa de tomate',
              instruction:
                  'Añade el tomate y las especias. Cocina a fuego medio-bajo hasta obtener una salsa espesa y bien aromática.',
              timerMinutes: 8,
              timerLabel: 'Espesar salsa de tomate',
              relevantIngredientIds: ['shk_2', 'shk_5'],
            ),
            CookingStep(
              id: 'shk_step_3',
              stepNumber: 3,
              title: 'Cascar los huevos y tapar',
              instruction:
                  'Con una cuchara haz 4 pequeños huecos en la salsa. Casca un huevo en cada hueco. Tapa la sartén y cocina hasta que las claras cuajen pero las yemas sigan líquidas.',
              timerMinutes: 5,
              timerLabel: 'Cuajar huevos tapado',
              relevantIngredientIds: ['shk_1'],
              chefTip: 'Sirve inmediatamente con pan tostado o tortillas calientes.',
            ),
          ],
        ),

        // 9. Curry Verde Tailandés con Tofu
        const Recipe(
          id: 'curry-verde-tofu',
          title: 'Curry Verde Tailandés con Tofu',
          description:
              'Aromático, exótico y cremoso con leche de coco, pasta de curry verde, calabacín, berenjena y albahaca.',
          imageUrl:
              'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 30,
          difficulty: RecipeDifficulty.medio,
          defaultPortions: 3,
          dietaryTags: ['Vegetariano', 'Vegano', 'Sin Gluten', 'Asiática', 'Especiado'],
          isVegetarian: true,
          isVegan: true,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'cur_1',
                name: 'Tofu firme en cubos prensado',
                baseQuantity: 300,
                unit: 'g',
                category: 'Proteínas'),
            Ingredient(
                id: 'cur_2',
                name: 'Leche de coco cremosa',
                baseQuantity: 400,
                unit: 'ml',
                category: 'Líquidos'),
            Ingredient(
                id: 'cur_3',
                name: 'Pasta de curry verde tailandés',
                baseQuantity: 2,
                unit: 'cda',
                category: 'Salsas'),
            Ingredient(
                id: 'cur_4',
                name: 'Calabacín cortado en medias lunas',
                baseQuantity: 1,
                unit: 'unidad',
                category: 'Verduras'),
            Ingredient(
                id: 'cur_5',
                name: 'Salsa de soya o tamari sin gluten',
                baseQuantity: 2,
                unit: 'cda',
                category: 'Salsas'),
          ],
          steps: [
            CookingStep(
              id: 'cur_step_1',
              stepNumber: 1,
              title: 'Dorar los dados de tofu',
              instruction:
                  'Saltea el tofu en cubos en una sartén antiadherente con una pizca de aceite hasta que todos sus lados estén doraditos y firmes.',
              timerMinutes: 6,
              timerLabel: 'Dorar tofu',
              relevantIngredientIds: ['cur_1'],
            ),
            CookingStep(
              id: 'cur_step_2',
              stepNumber: 2,
              title: 'Despertar la pasta de curry',
              instruction:
                  'En una olla añade 3 cucharadas de la capa espesa de la leche de coco y fríe la pasta de curry verde durante 2 minutos hasta liberar los aromas.',
              relevantIngredientIds: ['cur_2', 'cur_3'],
            ),
            CookingStep(
              id: 'cur_step_3',
              stepNumber: 3,
              title: 'Hervir con verduras y tofu',
              instruction:
                  'Vierte el resto de la leche de coco, el calabacín, salsa de soya y el tofu dorado. Cocina a fuego suave.',
              timerMinutes: 10,
              timerLabel: 'Cocción curry',
              relevantIngredientIds: ['cur_2', 'cur_4', 'cur_5'],
            ),
          ],
        ),

        // 10. Tortilla Española Jugosa
        const Recipe(
          id: 'tortilla-espanola',
          title: 'Tortilla Española Jugosa',
          description:
              'El monumento de la gastronomía española: papas pochadas a fuego lento, cebolla caramelizada y centro tierno.',
          imageUrl:
              'https://images.unsplash.com/photo-1584947926227-2c1b2f7035bf?auto=format&fit=crop&w=800&q=80',
          prepTimeMinutes: 35,
          difficulty: RecipeDifficulty.medio,
          defaultPortions: 4,
          dietaryTags: ['Vegetariano', 'Sin Gluten', 'Española', 'Tradicional'],
          isVegetarian: true,
          isVegan: false,
          isGlutenFree: true,
          ingredients: [
            Ingredient(
                id: 'tor_1',
                name: 'Papas peladas y cortadas en láminas finas',
                baseQuantity: 600,
                unit: 'g',
                category: 'Tubérculos'),
            Ingredient(
                id: 'tor_2',
                name: 'Huevos grandes frescos',
                baseQuantity: 6,
                unit: 'unidades',
                category: 'Huevos'),
            Ingredient(
                id: 'tor_3',
                name: 'Cebolla dulce cortada en plumas',
                baseQuantity: 1,
                unit: 'unidad grande',
                category: 'Verduras'),
            Ingredient(
                id: 'tor_4',
                name: 'Aceite de oliva para pochar',
                baseQuantity: 250,
                unit: 'ml',
                category: 'Aceites'),
            Ingredient(
                id: 'tor_5',
                name: 'Sal fina',
                baseQuantity: 1,
                unit: 'cdta',
                category: 'Condimentos'),
          ],
          steps: [
            CookingStep(
              id: 'tor_step_1',
              stepNumber: 1,
              title: 'Pochar papas y cebolla a fuego lento',
              instruction:
                  'En una sartén con abundante aceite tibio pon las papas y cebolla saladas. No deben freírse crujientes sino confitarse blanditas.',
              timerMinutes: 16,
              timerLabel: 'Confitar papas y cebolla',
              relevantIngredientIds: ['tor_1', 'tor_3', 'tor_4'],
            ),
            CookingStep(
              id: 'tor_step_2',
              stepNumber: 2,
              title: 'Mezclar con los huevos batidos',
              instruction:
                  'Escurre bien el aceite de las papas y échalas calientes en el tazón con los huevos batidos. Deja reposar 5 minutos para que la papa absorba el huevo.',
              relevantIngredientIds: ['tor_2'],
            ),
            CookingStep(
              id: 'tor_step_3',
              stepNumber: 3,
              title: 'Cuajar y voltear',
              instruction:
                  'En una sartén antiadherente con un hilo de aceite muy caliente, vierte la mezcla. Con una espátula da forma a los bordes. A los 2 minutos, coloca un plato llano encima, voltea con decisión y desliza de vuelta para sellar el otro lado.',
              timerMinutes: 4,
              timerLabel: 'Cuajado y sellado',
              chefTip: 'Para una tortilla jugosa y babé por dentro, no sobrepases los 2 minutos por lado.',
            ),
          ],
        ),
      ];
}
