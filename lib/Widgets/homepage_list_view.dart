import 'package:bikesetupapp/Services/alert_dialogs.dart';
import 'package:bikesetupapp/Services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePageListView extends StatefulWidget {
  final User? user;
  final String bikename;
  final String category;
  final String setup;
  const HomePageListView(
      {super.key,
      required this.user,
      required this.bikename,
      required this.category,
      required this.setup});

  @override
  State<HomePageListView> createState() => _HomePageListViewState();
}

class _HomePageListViewState extends State<HomePageListView> {
  late Future<void> initData;
  late bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DatabaseService('${widget.user?.uid}')
          .getSettings(widget.bikename, widget.category, widget.setup),
      builder: ((context, AsyncSnapshot snapshot) {
        if (ConnectionState.waiting == snapshot.connectionState) {
          return const Center(
              child: CircularProgressIndicator
                  .adaptive()); //TODO: Change color to Theme
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        } else if (snapshot.data == null || snapshot.data!.data() == null) {
          // Data is still being fetched or it's null, show a loading indicator or message
          return const Center(child: CircularProgressIndicator.adaptive());
        } else {
          Map<String, dynamic>? settings =
              snapshot.data!.data() as Map<String, dynamic>?;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 5),
            itemCount: settings?.length,
            itemBuilder: (context, index) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                child: ListTile(
                  leading: IconButton(
                      tooltip: 'Edit Setting',
                      onPressed: () {
                        AlertDialogs.editValue(
                            context,
                            widget.user!,
                            settings!.keys.elementAt(index),
                            settings.values.elementAt(index),
                            widget.bikename,
                            widget.category,
                            widget.setup);
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).iconTheme.color,
                      )),
                  title: settings == null
                      ? Text('No Data...',
                          style: Theme.of(context).textTheme.labelMedium)
                      : Text(
                          settings.keys.elementAt(index),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                  subtitle: settings == null
                      ? Text('...',
                          style: Theme.of(context).textTheme.labelSmall)
                      : Text(
                          settings.values.elementAt(index),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                  trailing: IconButton(
                      tooltip: 'Delete Setting',
                      onPressed: () {
                        if (settings != null &&
                            settings.keys.elementAt(index) == 'Pressure') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pressure is not deletable'),
                            ),
                          );
                        } else {
                          AlertDialogs.deleteCategory(
                              context,
                              widget.user!,
                              settings!.keys.elementAt(index),
                              widget.bikename,
                              widget.category,
                              widget.setup);
                        }
                      },
                      icon: Icon(Icons.delete,
                          color: Theme.of(context).iconTheme.color)),
                ),
              );
            },
          );
        }
      }),
    );
  }
}
