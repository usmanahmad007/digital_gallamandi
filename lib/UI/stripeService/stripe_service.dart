import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  String stripeSecretKey = dotenv.env['stripeSecretKey'] ?? '';

  // =========================
  // MAIN PAYMENT FUNCTION
  // =========================
  Future<bool> makePayment(int amount) async {
    print(stripeSecretKey);
    print("🚀 ===== STRIPE PAYMENT START =====");
    print("💰 Amount received: $amount");
    print("🔑 Secret key exists: ${stripeSecretKey.isNotEmpty}");

    try {
      print("📡 Creating PaymentIntent...");

      String? paymentIntentClientSecret =
      await _createPaymentIntent(amount, 'pkr');

      print("🔐 Client Secret: $paymentIntentClientSecret");

      if (paymentIntentClientSecret == null) {
        print("❌ PaymentIntent is NULL");
        showToastMessage("Failed to initialize payment.");
        return false;
      }

      print("⚙️ Initializing Stripe Payment Sheet...");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Usman Ahmad",
        ),
      );

      print("📲 Presenting Payment Sheet...");

      bool flag = await _processPayment();

      print("📩 Payment result: $flag");

      if (flag == false) {
        print("❌ Payment failed in process step");
        showToastMessage("Error in proceeding with payment");
        return false;
      } else {
        print("✅ Payment Successful");
        showToastMessage("Payment Successful");
      }

      print("🏁 ===== STRIPE PAYMENT END =====");
      return true;
    } catch (e, stack) {
      print("🔥 ERROR in makePayment:");
      print(e);
      print("📍 Stacktrace:");
      print(stack);

      showToastMessage("Error in proceeding with payment");
      return false;
    }
  }

  // =========================
  // TOAST
  // =========================
  void showToastMessage(String message) {
    print("📢 TOAST: $message");

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // =========================
  // PAYMENT SHEET
  // =========================
  Future<bool> _processPayment() async {
    try {
      print("💳 Opening Stripe Payment Sheet...");

      await Stripe.instance.presentPaymentSheet();

      print("🎉 Payment Sheet completed successfully");
      return true;
    } catch (e, stack) {
      print("❌ Payment cancelled or failed:");
      print(e);
      print("📍 Stacktrace:");
      print(stack);

      showToastMessage("Payment has been cancelled");
      return false;
    }
  }

  // =========================
  // CREATE PAYMENT INTENT
  // =========================
  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      print("🌐 ===== CREATING PAYMENT INTENT =====");
      print("💰 Raw amount: $amount");
      print("💱 Currency: $currency");
      print("🔑 Secret key length: ${stripeSecretKey.length}");

      final Dio dio = Dio();

      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
        "payment_method_types[]": "card",
      };

      print("📦 Request Data:");
      print(data);

      print("📡 Sending request to Stripe...");

      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $stripeSecretKey",
          },
        ),
      );

      print("📨 Stripe Response Status: ${response.statusCode}");
      print("📨 Stripe Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        print("✅ PaymentIntent created successfully");

        return response.data["client_secret"];
      } else {
        print("❌ Failed PaymentIntent: ${response.statusCode}");
        showToastMessage("Failed to create PaymentIntent.");
      }

      return null;
    } catch (e, stack) {
      print("🔥 ERROR creating PaymentIntent:");
      print(e);
      print("📍 Stacktrace:");
      print(stack);

      showToastMessage("Failed to create PaymentIntent.");
      return null;
    }
  }

  // =========================
  // AMOUNT CONVERSION
  // =========================
  String _calculateAmount(int amount) {
    final calculatedAmount = amount * 100;

    print("🧮 Calculating amount:");
    print("➡️ Input: $amount");
    print("➡️ Output (cents): $calculatedAmount");

    return calculatedAmount.toString();
  }
}