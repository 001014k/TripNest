import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/list_viewmodel.dart';
import 'marker_info_view.dart';

class ListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ListViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('여행 리스트'),
        ),
        body: Consumer<ListViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Text(viewModel.errorMessage!, style: TextStyle(color: Colors.red)));
            }

            return ListView.builder(
              itemCount: viewModel.lists.length,
              itemBuilder: (context, index) {
                final list = viewModel.lists[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.format_list_bulleted),
                        title: Text(
                          list.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('마커 갯수: ${list.markerCount}'),
                        onTap: () => _showListOptions(context, list.id, viewModel),
                      ),
                      Divider(),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateListDialog(context),
          backgroundColor: Colors.white,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController _listNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 리스트 생성'),
          content: TextField(
            controller: _listNameController,
            decoration: InputDecoration(labelText: '리스트 이름'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Provider.of<ListViewModel>(context, listen: false)
                    .createList(_listNameController.text);
                Navigator.of(context).pop();
              },
              child: Text('생성'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _showListOptions(BuildContext context, String listId, ListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.format_list_bulleted),
              title: Text(
                '리스트 열기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkerInfoPage(listId: listId),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text(
                '리스트 삭제',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('리스트 삭제'),
                      content: Text('리스트를 삭제할건가요?'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('삭제'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('취소'),
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true) {
                  await viewModel.deleteList(listId);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
