enum Category {
  forYou('for_you', 'For You'),
  newReleases('new', 'New'),
  hot('hot', 'Hot'),
  romance('romance', 'Romance'),
  ceo('ceo', 'CEO'),
  revenge('revenge', 'Revenge'),
  family('family', 'Family'),
  action('action', 'Action'),
  fantasy('fantasy', 'Fantasy'),
  recommended('recommended', 'Recommended'),
  // Kept for compatibility with older serialized filters. The UI no longer
  // exposes these misleading labels; repository mapping redirects them to
  // the corresponding real taxonomy.
  adventure('adventure', 'Action'),
  scary('scary', 'Fantasy'),
  anime('anime', 'Recommended'),
  vip('vip', 'VIP');

  const Category(this.id, this.displayName);

  final String id;
  final String displayName;

  static Category fromId(String id) => switch (id) {
        'adventure' => Category.action,
        'scary' => Category.fantasy,
        'anime' => Category.recommended,
        _ => Category.values.firstWhere(
            (category) => category.id == id,
            orElse: () => Category.newReleases,
          ),
      };
}
