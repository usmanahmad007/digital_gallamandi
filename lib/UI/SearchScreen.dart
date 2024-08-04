import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchResults = [];
  List<String> _data = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape'];

  void _performSearch(String query) {
    setState(() {
      _searchResults = _data
          .where((element) => element.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _searchFocusNode.hasFocus ? Colors.greenAccent.withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _searchFocusNode.hasFocus? Colors.green:Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: _searchFocusNode.hasFocus ? Colors.green : Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _performSearch(value);
                  },
                ),
              ),
              Icon(Icons.filter_list, color: _searchFocusNode.hasFocus ? Colors.green : Colors.grey),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _searchResults.isEmpty
          ? SingleChildScrollView(
            child: Column(
                    children: [
            if(_searchController.text.isNotEmpty && _searchResults.isEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
            
                      RichText(
                        text: TextSpan(
                          text: 'Result for ',
                          style: TextStyle(color: Colors.black,fontSize: 24), // Default style
                          children: <TextSpan>[
                            TextSpan(
                              text: '\"${_searchController.text}\"',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green,fontSize: 24), // Styled text
                            ),
                          ],
                        ),
                      ),
                      Text("0 found",style: TextStyle(color: Colors.green),),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
            
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: height/6,),
                        Image.asset("assets/emptyResult.png"),
                        Text("Not found",style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.bold),),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Text("Sorry, the keyword you entered cannot be found,please check again or search with another keyword",textAlign: TextAlign.center,),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            if(_searchController.text.isEmpty)
              Container(
                height: height/1.2,
                child: Center(
                  child: Text("Search here"),
                ),
              )
            
            
                    ],
                  ),
          )
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_searchResults[index]),
          );
        },
      ),
    );
  }
}
