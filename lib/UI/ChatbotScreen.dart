import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, String>> qaList = [
    {
      'question': 'سوال 1: چار موسموں میں اگائی جانے والی اہم فصلیں کون سی ہیں؟',
      'answer': 'اہم فصلیں:\n\nبہار: گندم، جو\nگرمی: چاول، مکئی\nخزاں: سویابین، مکئی\nسردی: آلو، پتے والی سبزیاں'
    },
    {
      'question': 'سوال 2: گندم، چاول، مکئی، کھیرے، ٹماٹر، آلو وغیرہ کے لئے کون سی کھاد مناسب ہے؟',
      'answer': 'گندم: نائٹروجن پر مبنی کھاد\nچاول: یوریا، فاسفیٹ کھادیں\nمکئی: نائٹروجن، فاسفورس، پوٹاشیم\nکھیرا: کمپوسٹ، اچھی طرح سے سڑی ہوئی کھاد\nٹماٹر: متوازن این پی کے (10-10-10) کھاد\nآلو: اعلی پوٹاشیم کھاد'
    },
    {
      'question': 'سوال 3: کپاس، چاول، گندم، آلو، ٹماٹر وغیرہ اگانے کا صحیح موسم کون سا ہے؟',
      'answer': 'کپاس: بہار\nچاول: دیر بہار/ابتدائی گرمی\nگندم: سردی\nآلو: بہار/خزاں\nٹماٹر: دیر بہار/گرمی'
    },
    {
      'question': 'سوال 4: کپاس، گندم، چاول، آم، مالٹے کے لئے کون سے مناسب کیڑے مار ادویات ہیں؟',
      'answer': 'کپاس: آرگینو فاسفیٹس، پیریتھرائڈز\nگندم: فنگسائڈز (زنگ کے لئے)، انسیکٹسائڈز (افڈز کے لئے)\nچاول: انسیکٹسائڈز (بوررز کے لئے)، فنگسائڈز (بلاسٹ کے لئے)\nآم: نیم تیل، انسیکٹسائڈز (فروٹ فلائز کے لئے)\nمالٹے: ہارٹیکلچرل آئلز، انسیکٹسائڈز (افڈز کے لئے)'
    },
    {
      'question': 'سوال 5: سبزیاں، پھل، اور پھول اگانے کے لئے زمین کی تیاری کیسے کرنی چاہیے؟',
      'answer': 'مٹی کا ٹیسٹ کریں اور ضرورت کے مطابق درست کریں۔\nمٹی کو ہوا دار بنانے کے لئے ٹیل کریں۔\nنامیاتی مادہ جیسے کمپوسٹ شامل کریں۔\nبہتر نکاسی کے لئے ریزڈ بیڈز بنائیں۔\nنمی برقرار رکھنے اور جڑی بوٹیوں کے کنٹرول کے لئے ملچ کریں۔'
    },
    {
      'question': 'سوال 6: اپنی فصلوں کو زیادہ منافع حاصل کرنے کے لئے کیسے مارکیٹ کر سکتے ہیں؟',
      'answer': 'سوشل میڈیا اور آن لائن پلیٹ فارم کا استعمال کریں۔\nکسان مارکیٹوں میں شرکت کریں۔\nوسائل کو جمع کرنے کے لئے کوآپریٹوز بنائیں۔\nصارفین یا مقامی ریستوران کو براہ راست فروخت کریں۔\nویلیو بڑھانے کے لئے آرگینک یا دیگر سرٹیفیکیشن حاصل کریں۔'
    },
    {
      'question': 'سوال 7: توانائی کے وسائل، بجلی، پیٹرولیم کے بحرانوں سے سمارٹ طریقے سے کیسے نمٹا جا سکتا ہے؟',
      'answer': 'قابل تجدید توانائی کے ذرائع (سولر، ونڈ) کا استعمال کریں۔\nتوانائی کی بچت کے نظام کا نفاذ کریں۔\nکم ایندھن استعمال کرنے والے طریقے اپنائیں۔\nبایوفیولز اور الیکٹرک مشینری کا استعمال کریں۔\nلوجسٹکس اور ٹرانسپورٹیشن کو بہتر بنائیں۔'
    },
    {
      'question': 'سوال 8: کیا ڈرون زراعت میں کھیتوں میں کیڑے مارنے کے لئے مددگار ہے؟',
      'answer': 'جی ہاں، ڈرون زراعت میں کیڑے مارنے کے لئے بہت مددگار ہیں، مزدوروں کی قیمت کو کم کرنے اور کیمیکلز کے اثرات سے بچانے کے لئے۔'
    },
    {
      'question': 'سوال 9: ہم پودوں کی بیماری کی تشخیص کیسے کر سکتے ہیں تاکہ صحت مند فصلیں حاصل ہو سکیں؟',
      'answer': 'پودوں کی بیماریوں کی تشخیص بصری معائنہ، لیبارٹری ٹیسٹنگ اور جدید ٹیکنالوجیز جیسے ریموٹ سینسنگ اور AI پر مبنی آلات سے کی جا سکتی ہے۔'
    },
    {
      'question': 'سوال 10: جدید ٹیکنالوجیز کا استعمال کرکے ہم کس طرح صحت مند فصلوں کا تناسب بڑھا سکتے ہیں؟',
      'answer': 'جدید زراعت کے آلات، سینسرز، ڈرونز، سیٹلائٹ امیجری، خودکار آبپاشی نظام، اور ڈیٹا اینالیٹکس کا استعمال کرکے زراعت کے طریقوں کو بہتر بنایا جا سکتا ہے اور فصلوں کی صحت کو بہتر بنایا جا سکتا ہے۔'
    },
    {
      'question': 'سوال 11: کیا AI زراعت میں مددگار ہے؟',
      'answer': 'جی ہاں، AI زراعت میں پیش گوئی کرنے، فصل کی بیماریوں کی تشخیص کرنے، وسائل کے استعمال کو بہتر بنانے، کاموں کو خودکار بنانے، اور فیصلہ سازی کے عمل کو بہتر بنانے میں مددگار ہے۔'
    },
    {
      'question': 'Q1: What are the main crops cultivated in four seasons?',
      'answer': 'Main crops include:\n\nSpring: Wheat, barley\nSummer: Rice, maize\nAutumn: Soybeans, corn\nWinter: Potatoes, leafy greens'
    },
    {
      'question': 'Q2: What kind of fertilizer is suitable for wheat, rice, corn, cucumber, tomato, potato, etc.?',
      'answer': 'Wheat: Nitrogen-based fertilizers\nRice: Urea, phosphate fertilizers\nCorn: Nitrogen, phosphorus, potassium\nCucumber: Compost, well-rotted manure\nTomato: Balanced NPK (10-10-10) fertilizers\nPotato: High potassium fertilizers'
    },
    {
      'question': 'Q3: What is the right season to grow cotton, rice, wheat, potato, tomato, etc.?',
      'answer': 'Cotton: Spring\nRice: Late spring/early summer\nWheat: Winter\nPotato: Spring/fall\nTomato: Late spring/summer'
    },
    {
      'question': 'Q4: What are the suitable pesticides for cotton, wheat, rice, mangoes, oranges?',
      'answer': 'Cotton: Organophosphates, pyrethroids\nWheat: Fungicides (for rust), insecticides (for aphids)\nRice: Insecticides (for borers), fungicides (for blast)\nMangoes: Neem oil, insecticides (for fruit flies)\nOranges: Horticultural oils, insecticides (for aphids)'
    },
    {
      'question': 'Q5: How should a farmer prepare land to grow vegetables, fruits, and flowers?',
      'answer': 'Test soil and amend as needed.\nTill the soil to improve aeration.\nAdd organic matter like compost.\nCreate raised beds for better drainage.\nMulch to retain moisture and control weeds.'
    },
    {
      'question': 'Q6: How can we market our crops to get more profits?',
      'answer': 'Use social media and online platforms.\nParticipate in farmers\' markets.\nForm cooperatives to pool resources.\nDirect selling to consumers or local restaurants.\nObtain organic or other certifications to add value.'
    },
    {
      'question': 'Q7: How can we smartly overcome the crises of energy resources, electricity, petroleum to cultivate crops?',
      'answer': 'Use renewable energy sources (solar, wind).\nImplement energy-efficient irrigation systems.\nAdopt conservation tillage to reduce fuel use.\nUse biofuels and electric machinery.\nOptimize logistics and transportation to reduce energy consumption.'
    },
    {
      'question': 'Q8: Is drone helpful in agriculture to spray the pesticide in farms?',
      'answer': 'Yes, drones are very helpful in agriculture for spraying pesticides efficiently, reducing labor costs, and minimizing chemical exposure to workers.'
    },
    {
      'question': 'Q9: How can we diagnose the plant disease to get healthy crops?',
      'answer': 'Plant diseases can be diagnosed using visual inspection, laboratory testing, and advanced technologies like remote sensing and AI-based tools for early and accurate detection.'
    },
    {
      'question': 'Q10: What kind of measures can we take to get a healthy percentage of crops by using modern technologies?',
      'answer': 'Measures include using precision agriculture tools, sensors, drones, satellite imagery, automated irrigation systems, and data analytics to optimize farming practices and improve crop health.'
    },
    {
      'question': 'Q11: Is AI helpful in agriculture?',
      'answer': 'Yes, AI is helpful in agriculture for predicting crop yields, diagnosing plant diseases, optimizing resource use, automating tasks, and improving decision-making processes.'
    },
  ];

  Map<int, bool> visibilityMap = {};

  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Agriculture Expert'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: qaList.length,
          itemBuilder: (context, index) {
            final qa = qaList[index];
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      visibilityMap[index] = !(visibilityMap[index] ?? false);
                    });
                  },
                  child: Container(
                    color: Colors.grey[300],
                    width: width/0.9,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      qa['question']!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Visibility(
                  visible: visibilityMap[index] ?? false,
                  child: Container(
                    color: Colors.green[100],
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      qa['answer']!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ChatbotScreen(),
  ));
}
