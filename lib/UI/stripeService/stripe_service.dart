import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();
  String stripeSecretKey = dotenv.env['stripeSecretKey'] ?? '';
  Future<bool> makePayment(int amount) async {
    try {
      String? paymentIntentClientSecret = await _createPaymentIntent(amount, 'pkr');

      if (paymentIntentClientSecret == null) {
        showToastMessage("Failed to initialize payment.");
        return false;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Usman Ahmad",
        ),
      );

      bool flag = await _processPayment();
      print("Payment Successful$flag");
      if (flag==false) {
        showToastMessage("Error in proceeding with payment");
        return false;
      } else {
        showToastMessage("Payment Successful");
      }
      return true;
    } catch (e) {
      print("Error in makePayment: $e");
      showToastMessage("Error in proceeding with payment");
      return false;
    }
  }

  void showToastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<bool> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    //  await Stripe.instance.confirmPaymentSheetPayment();
      return true;
    } catch (e) {
      print("Payment cancelled or failed: $e");
      showToastMessage("Payment has been cancelled");
      return false;
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
      };

      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $stripeSecretKey",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data["client_secret"];
      } else {
        print("Failed to create PaymentIntent: ${response.statusCode}");
        showToastMessage("Failed to create PaymentIntent. Please try again.");
      }
      return null;
    } catch (e) {
      print("Error creating PaymentIntent: $e");
      showToastMessage("Failed to create PaymentIntent. Please try again.");
      return null;
    }
  }

  String _calculateAmount(int amount) {
    final calculatedAmount = amount * 100; // Convert to the smallest currency unit
    return calculatedAmount.toString();
  }
}
