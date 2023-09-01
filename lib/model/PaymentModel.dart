import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  num amount;

  num? exchangeRate;

  String? bank, email, fullName, phone, paymentId;

  bool confirmed;

  String paymentMethod;

  Timestamp? confirmDate;

  Timestamp date;

  PaymentModel(
      {
      required this.amount,
      this.exchangeRate,
      required this.paymentMethod,
      this.bank,
      this.email,
      required this.confirmed,
      this.fullName,
      this.phone,
      this.paymentId,
      required this.date,
      this.confirmDate,
      });

  factory PaymentModel.fromJson(Map<String, dynamic> parsedJson) {
    return PaymentModel(
      amount: parsedJson["amount"] ?? 0,
      exchangeRate: parsedJson["exchange_rate"],
      bank: parsedJson["bank"],
      email: parsedJson["email"],
      confirmed: parsedJson["confirmed"] ?? false,
      fullName: parsedJson["full_name"],
      phone: parsedJson["phone"],
      paymentId: parsedJson["payment_id"],
      date: parsedJson["date"],
      confirmDate: parsedJson["confirm_date"],
      paymentMethod: parsedJson["payment_method"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': this.amount,
      'exchange_rate': this.exchangeRate,
      'bank': this.bank,
      'email': this.email,
      'confirmed': this.confirmed,
      'full_name': this.fullName,
      'phone': this.phone,
      'payment_id': this.paymentId,
      'date': this.date,
      'confirm_date': this.confirmDate,
      'payment_method': this.paymentMethod,
    };
  }
}
