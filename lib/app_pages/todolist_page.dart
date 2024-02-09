import 'package:bikesetupapp/alert_dialogs/todo_list_alert_dialogs.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ToDoList extends StatefulWidget {
  final User user;
  final String ubid;
  final String bikename;
  const ToDoList(
      {super.key,
      required this.user,
      required this.ubid,
      required this.bikename});

  @override
  State<ToDoList> createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        widget.bikename,
        style: Theme.of(context).textTheme.titleLarge,
      )),
      body: StreamBuilder(
        stream: DatabaseService(widget.user.uid).getTodoList(widget.ubid),
        builder: ((context, AsyncSnapshot snapshot) {
          if (ConnectionState.waiting == snapshot.connectionState) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          } else {
            if (snapshot.data.docs.isEmpty) {
              return const Center(child: Text('You have nothing to do!'));
            } else {
              return ListView(
                shrinkWrap: true,
                children: [
                  ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        'Todo',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      trailing: Icon(Icons.list,
                          color: Theme.of(context).textTheme.labelLarge!.color),
                      children: [
                        SizedBox(
                            child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot data = snapshot.data.docs[index];
                            return Visibility(
                                visible: !data['done'],
                                child: Card(
                                    child: ListTile(
                                  onTap: () {
                                    TodoAlerts.editTodo(
                                        context,
                                        widget.ubid,
                                        data.id,
                                        widget.user,
                                        data['taskname'],
                                        data['taskdescription'],
                                        data['Part'],
                                        data['done']);
                                  },
                                  title: Text(
                                    data['taskname'],
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  subtitle: Text(
                                    data['taskdescription'],
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: Checkbox(
                                    activeColor: Theme.of(context).primaryColor,
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .color!),
                                    value: data['done'],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        DatabaseService(widget.user.uid)
                                            .updateTodoList(
                                                widget.ubid, data.id, value!);
                                      });
                                    },
                                  ),
                                )));
                          },
                        )),
                      ]),
                  ExpansionTile(
                    title: Text(
                      'Done',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    trailing: Icon(Icons.done_all,
                        color: Theme.of(context).textTheme.labelLarge!.color),
                    children: [
                      SizedBox(
                          child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot data = snapshot.data.docs[index];
                          return Visibility(
                              visible: data['done'],
                              child: Card(
                                  child: ListTile(
                                onTap: () {
                                  TodoAlerts.editTodo(
                                      context,
                                      widget.ubid,
                                      data.id,
                                      widget.user,
                                      data['taskname'],
                                      data['taskdescription'],
                                      data['Part'],
                                      data['done']);
                                },
                                title: Text(
                                  data['taskname'],
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                subtitle: Text(
                                  data['taskdescription'],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: Checkbox(
                                  activeColor: Theme.of(context).primaryColor,
                                  side: BorderSide(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color!),
                                  value: data['done'],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      DatabaseService(widget.user.uid)
                                          .updateTodoList(
                                              widget.ubid, data.id, value!);
                                    });
                                  },
                                ),
                              )));
                        },
                      )),
                    ],
                  )
                ],
              );
            }
          }
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TodoAlerts.newTodo(context, widget.ubid, widget.user);
        },
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
