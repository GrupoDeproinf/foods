class TopSellingModel {
  String? id;
  String? name;
  String? description;
  String? image;
  String? restaurantID;
  String? price;
  String? productID;

  TopSellingModel({this.id, this.name, this.description, this.image, this.restaurantID, this.price, this.productID});

  TopSellingModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    image = json['image'] ?? "";
    restaurantID = json['restaurant_id'];
    price = json['price'] ?? "";
    productID = json['productID'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['image'] = this.image;
    data['restaurant_id'] = this.restaurantID;
    data['price'] = this.price ?? "";
    data['productID'] = this.productID ?? '';
    return data;
  }
}
