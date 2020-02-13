import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

const request = "https://pedrohnf688-projetoesig.herokuapp.com/tarefa";

const Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

enum WhyFarther { Todos, Ativos, Feitos }

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  final _toDoController = TextEditingController();
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;
  WhyFarther _selecionado;

  @override
  void initState() {
    super.initState();
    this._getListAllDataState();
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
//      _toDoList.sort((a, b) {
//        if (a["status"] && !b["status"])
//          return 1;
//        else if (!a["status"] && b["status"])
//          return -1;
//        else
//          return 0;
//      });
      _getListAllDataState();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Tarefas"),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: _mudarStatusTarefas),
            PopupMenuButton<WhyFarther>(
              onSelected: (WhyFarther result) {
                setState(() {
                  _selecionado = result;
                  print(_selecionado);
                  if (result == WhyFarther.Ativos) {
                    _listarTarefasAtivas();
                  } else if (result == WhyFarther.Feitos) {
                    _listarTarefasFeitas();
                  } else if (result == WhyFarther.Todos) {
                    _getListAllDataState();
                  }
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<WhyFarther>>[
                const PopupMenuItem<WhyFarther>(
                    value: WhyFarther.Ativos,
                    child: Text('Ativos',
                        style: TextStyle(color: Colors.black, fontSize: 15))),
                const PopupMenuItem<WhyFarther>(
                    value: WhyFarther.Feitos,
                    child: Text('Concluídos',
                        style: TextStyle(color: Colors.black, fontSize: 15))),
                const PopupMenuItem<WhyFarther>(
                    value: WhyFarther.Todos,
                    child: Text('Todos',
                        style: TextStyle(color: Colors.black, fontSize: 15)))
              ],
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  )),
                  RaisedButton(
                      color: Colors.blueAccent,
                      child: Text("ADD"),
                      onPressed: () {
                        _postData(_toDoController.text, false, null);
                      })
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
                    child: ListView.builder(
                        padding: EdgeInsets.only(top: 10.0),
                        itemCount: _toDoList.length,
                        itemBuilder: buildItem),
                    onRefresh: _refresh))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.delete,
          ),
          backgroundColor: Colors.blue,
          onPressed: _deleteDataByCompleted,
        ));
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["nome"]),
        value: _toDoList[index]["status"],
        secondary: CircleAvatar(
            child:
                Icon(_toDoList[index]["status"] ? Icons.check : Icons.error)),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["status"] = c;
            this._postData(_toDoList[index]["nome"], _toDoList[index]["status"],
                _toDoList[index]["id"]);
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          //   _saveData();
          this._deleteDataById(_lastRemoved["id"]);

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["nome"]}\" removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    this._postData(_lastRemoved["nome"], _lastRemoved["status"],
                        _lastRemoved["id"]);
                  });
                }),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

// Requisições da api rest

// listar todos as tarefas da lista, redesenhando a tela.
  Future<Null> _getListAllDataState() async {
    http.Response response = await http.get(request);
    setState(() {
      this._toDoList = json.decode(response.body);
    });
  }

// Cadastro e Atualização da tarefa.
  void _postData(String name, bool status, int id) async {
    Map<String, dynamic> body = Map();

    if (id != null) {
      body["id"] = id;
      body["nome"] = name;
      body["status"] = status;
    } else {
      body["nome"] = name;
      body["status"] = status;
    }

    http.Response response =
        await http.post(request, headers: headers, body: json.encode(body));
    print(response.statusCode);
    print(response.body);

    this._getListAllDataState();
    this._toDoController.text = "";
  }

// Deletar tarefa por id.
  Future<Null> _deleteDataById(int id) async {
    http.Response response =
        await http.delete(request + "/${id}", headers: headers);
    this._getListAllDataState();
  }

// Deletar todas as tarefas já feitas.
  Future<Null> _deleteDataByCompleted() async {
    http.Response response = await http.delete(request, headers: headers);
    this._getListAllDataState();
  }

// Listar todas as tarefas feitas.
  Future<Null> _listarTarefasFeitas() async {
    http.Response response = await http.get(request + "/feitas");
    setState(() {
      this._toDoList = json.decode(response.body);
    });
  }

// Listar todas tarefas ativas.
  Future<Null> _listarTarefasAtivas() async {
    http.Response response = await http.get(request + "/ativas");
    setState(() {
      this._toDoList = json.decode(response.body);
    });
  }

  // Mudando o status das tarefas.
  Future<Null> _mudarStatusTarefas() async {
    http.Response response = await http.get(request + "/statusLista");
    this._getListAllDataState();
  }
}
