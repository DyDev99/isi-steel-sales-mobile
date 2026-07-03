enum ShopType {
  retailShop('Retail Shop'),
  wholesaleDepot('Wholesale Depot'),
  hardwareStore('Hardware Store'),
  constructionSupplier('Construction Supplier'),
  distributor('Distributor');

  const ShopType(this.label);
  final String label;
}
