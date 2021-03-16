import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/customer.dart';
import '../helpers/database_helper.dart';
import '../widgets/image_dialog.dart';

class CustomersScreeen extends StatefulWidget {
  static final String routeName = "/allcustomers";
  @override
  _CustomersScreeenState createState() => _CustomersScreeenState();
}

class _CustomersScreeenState extends State<CustomersScreeen> {
  final dbHelper = DatabaseHelper.instance;
  List<Customer> _customers;
  Future _fetchCustomers;

  Future<void> _loadDBData() async {
    try {
      List<Customer> customers = List<Customer>();
      List<Map<String, dynamic>> allRows = await dbHelper.queryAllRows();

      allRows.forEach((row) {
        var customer = new Customer(
          id: row[DatabaseHelper.columnId],
          platformIMEI: row[DatabaseHelper.columnIMEI],
          firstName: row[DatabaseHelper.columnFirstName],
          lastName: row[DatabaseHelper.columnLastName],
          dob: DateTime.parse(row[DatabaseHelper.columnDob]),
          passport: row[DatabaseHelper.columnPassportNumber],
          email: row[DatabaseHelper.columnEmail],
          imagePath: row[DatabaseHelper.columnImagePath],
          deviceName: row[DatabaseHelper.columnDeviceName],
          lat: row[DatabaseHelper.columnLat].toString(),
          lng: row[DatabaseHelper.columnLng].toString(),
        );
        customers.add(customer);
      });
      setState(() {
        _customers = customers;
      });
    } catch (error) {
      print("An error during loading customers has occurred");
      print(error.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers = _loadDBData();
  }

  @override
  Widget build(BuildContext context) {
    DateFormat formatter = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text("All Customers"),
        brightness: Brightness.light,
      ),
      body: FutureBuilder(
        future: _fetchCustomers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return (_customers == null || _customers.length == 0)
                ? Center(
                    child: Text(
                        "No Avaiable Customers yet! Pleaase register some"))
                : ListView.builder(
                    itemCount: _customers == null ? 0 : _customers.length,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        // leading: Image.file(File(_customers[index].imagePath),
                        //     height: 100, width: 100, fit: BoxFit.fitWidth),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("Id: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                    child:
                                        Text(_customers[index].id.toString()))
                              ],
                            ),
                            Row(children: [
                              Text("Name: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(_customers[index].firstName +
                                    " " +
                                    _customers[index].lastName),
                              )
                            ]),
                            Row(
                              children: [
                                Text("IMEI: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                    child:
                                        Text(_customers[index].platformIMEI)),
                              ],
                            ),
                            Row(
                              children: [
                                Text("Dob: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                    child: Text(formatter
                                        .format(_customers[index].dob)))
                              ],
                            ),
                            Row(
                              children: [
                                Text("Email: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(_customers[index].email)),
                              ],
                            ),
                            Row(
                              children: [
                                Text("Passport: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                    child: Text(_customers[index].passport))
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  "Device: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                    child: Text(_customers[index].deviceName)),
                              ],
                            ),
                            Row(
                              children: [
                                Text("Lat: ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(_customers[index].lat)),
                              ],
                            ),
                            Row(children: [
                              Text("Lng: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(_customers[index].lng))
                            ]),
                            Row(children: [
                              Text("Path: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    await showDialog(
                                        context: context,
                                        builder: (_) => ImageDialog(
                                            _customers[index].imagePath));
                                  },
                                  child: Text(_customers[index].imagePath),
                                ),
                              )
                            ]),
                          ],
                        ),
                      ),
                    ),
                  );
          } else {
            return Center(
                child: CircularProgressIndicator(
              backgroundColor: Theme.of(context).primaryColor,
            ));
          }
        },
      ),
    );
  }
}
