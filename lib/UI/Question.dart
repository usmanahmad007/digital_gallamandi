class Question {
  final String question;
  final String answer;

  Question({required this.question, required this.answer});
}

List<Question> questions = [
  Question(
    question: 'چار موسموں میں اگائی جانے والی اہم فصلیں کون سی ہیں؟',
    answer: '''اہم فصلیں:
    - بہار: گندم، جو
    - گرمی: چاول، مکئی
    - خزاں: سویابین، مکئی
    - سردی: آلو، پتے والی سبزیاں''',
  ),
  Question(
    question: 'گندم، چاول، مکئی، کھیرے، ٹماٹر، آلو وغیرہ کے لئے کون سی کھاد مناسب ہے؟',
    answer: '''- گندم: نائٹروجن پر مبنی کھاد
    - چاول: یوریا، فاسفیٹ کھاد
    - مکئی: نائٹروجن، فاسفورس، پوٹاشیم
    - کھیرے: کمپوسٹ، اچھا کھاد والا گوبر
    - ٹماٹر: بیلنسڈ این پی کے (10-10-10) کھاد
    - آلو: پوٹاشیم کی اعلیٰ مقدار والی کھاد''',
  ),
  // Add more questions here...
];
