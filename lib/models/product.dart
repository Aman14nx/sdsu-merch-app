// lib/models/product.dart

class Product {
  final String id;
  final String title;
  final String category;
  final double basePrice;
  final double rating;
  final int reviewCount;
  final String description;
  final String imageUrl;

  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.imageUrl,
  });
}

class Accessory {
  final String id;
  final String name;
  final double price;

  const Accessory({
    required this.id,
    required this.name,
    required this.price,
  });
}

// Sample data
final List<Product> sampleProducts = [
  const Product(
    id: '1',
    title: 'SDSU Classic Campus Hoodie',
    category: 'Hoodies',
    basePrice: 54.99,
    rating: 4.8,
    reviewCount: 128,
    description: 'The ultimate campus essential. Premium fleece construction with embroidered SDSU logo. Perfect for game days, study sessions, and everything in between.',
    imageUrl: 'assets/Black.jpg',
  ),
  const Product(
    id: '2',
    title: 'SDSU Vintage Tee',
    category: 'T-Shirts',
    basePrice: 29.99,
    rating: 4.7,
    reviewCount: 94,
    description: 'Soft, breathable cotton tee with a vintage-inspired SDSU print. A wardrobe staple for every Jackrabbit.',
    imageUrl: 'assets/Tblue.jpg',
  ),
  const Product(
    id: '3',
    title: 'SDSU Track Pants',
    category: 'Pants',
    basePrice: 44.99,
    rating: 4.9,
    reviewCount: 61,
    description: 'Lightweight, moisture-wicking track pants with SDSU side stripe. Great for workouts or casual wear around campus.',
    imageUrl: 'assets/Pblue.jpg',
  ),
  const Product(
    id: '4',
    title: 'SDSU Quarter-Zip',
    category: 'Hoodies',
    basePrice: 64.99,
    rating: 4.2,
    reviewCount: 47,
    description: 'A versatile quarter-zip pullover with moisture management. Wear it to class, practice, or wherever your day takes you.',
    imageUrl: 'assets/Blue.jpg',
  ),
  const Product(
    id: '5',
    title: 'SDSU Spirit Jersey',
    category: 'T-Shirts',
    basePrice: 34.99,
    rating: 4.5,
    reviewCount: 83,
    description: 'Show your Jackrabbit pride in this bold oversized spirit jersey. Features screen-printed graphics and a relaxed fit.',
    imageUrl: 'assets/Twhite.jpg',
  ),
  const Product(
    id: '6',
    title: 'SDSU Jogger Sweats',
    category: 'Pants',
    basePrice: 49.99,
    rating: 4.1,
    reviewCount: 112,
    description: 'Cozy, tapered joggers with an embroidered SDSU mark. Premium French terry fabric for all-day comfort.',
    imageUrl: 'assets/Pblack.jpg',
  ),
  const Product(
    id: '7',
    title: 'SDSU Jogger Sweats',
    category: 'Hoodies',
    basePrice: 61.99,
    rating: 4.3,
    reviewCount: 112,
    description: 'Premium SDSU hoodie designed for comfort, warmth, and campus pride. Great for game day, class, or everyday wear',
    imageUrl: 'assets/Yellow.jpg',
  ),
      const Product(
    id: '8',
    title: 'SDSU Jogger Sweats',
    category: 'Hoodies',
    basePrice: 71.99,
    rating: 4.4,
    reviewCount: 112,
    description: 'Premium SDSU hoodie designed for comfort, warmth, and campus pride. Great for game day, class, or everyday wear',
    imageUrl: 'assets/white.jpg',
  ),
      const Product(
    id: '9',
    title: 'SDSU Jogger Sweats',
    category: 'T-Shirts',
    basePrice: 23.99,
    rating: 4.6,
    reviewCount: 112,
    description: 'Comfortable moisture-wicking SDSU performance tee for school, workouts, or everyday use.',
    imageUrl: 'assets/Tgray.jpg',
  ),
        const Product(
    id: '10',
    title: 'SDSU Jogger Sweats',
    category: 'T-Shirts',
    basePrice: 23.99,
    rating: 4.6,
    reviewCount: 112,
    description: 'Comfortable moisture-wicking SDSU performance tee for school, workouts, or everyday use.',
    imageUrl: 'assets/Tblack.jpg',
  ),
];

final List<Accessory> sampleAccessories = [
  const Accessory(id: 'a1', name: 'SDSU Pennant', price: 12.99),
  const Accessory(id: 'a2', name: 'SDSU Lanyard', price: 6.99),
  const Accessory(id: 'a3', name: 'SDSU Keychain', price: 5.99),
];