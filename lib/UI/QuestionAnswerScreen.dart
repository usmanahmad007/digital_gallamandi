import 'package:flutter/material.dart';
import 'question.dart';

class QuestionAnswerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('زرعی چیٹ بوٹ'),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(
              questions[index].question,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  questions[index].answer,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
