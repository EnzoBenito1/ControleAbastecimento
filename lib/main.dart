import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const FuelControlApp());
}

class Vehicle {
  String id;
  String name;
  String model;
  int year;
  String licensePlate;

  Vehicle({
    required this.id,
    required this.name,
    required this.model,
    required this.year,
    required this.licensePlate,
  });
}

class FuelRecord {
  final DateTime date;
  final double liters;
  final double pricePerLiter;
  final double odometer;
  final Vehicle vehicle;
  final String? notes;

  FuelRecord({
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.odometer,
    required this.vehicle,
    this.notes,
  });

  double get totalCost => liters * pricePerLiter;


  static double calculateConsumption(FuelRecord current, FuelRecord previous) {
    final distance = current.odometer - previous.odometer;
    return distance / current.liters;
  }
}


class FuelConsumptionStats {
  final List<FuelRecord> records;

  FuelConsumptionStats(this.records);

  double? getAverageConsumption() {
    if (records.length < 2) return null;


    final sortedRecords = List<FuelRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    double totalConsumption = 0;
    int validCalculations = 0;

    for (int i = 1; i < sortedRecords.length; i++) {
      final current = sortedRecords[i];
      final previous = sortedRecords[i - 1];

      if (current.vehicle.id == previous.vehicle.id) {
        final consumption = FuelRecord.calculateConsumption(current, previous);
        totalConsumption += consumption;
        validCalculations++;
      }
    }

    return validCalculations > 0 ? totalConsumption / validCalculations : null;
  }

  double? getLatestConsumption() {
    if (records.length < 2) return null;

    final sortedRecords = List<FuelRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort descending


    for (int i = 0; i < sortedRecords.length - 1; i++) {
      for (int j = i + 1; j < sortedRecords.length; j++) {
        if (sortedRecords[i].vehicle.id == sortedRecords[j].vehicle.id) {
          return FuelRecord.calculateConsumption(sortedRecords[i], sortedRecords[j]);
        }
      }
    }

    return null;
  }
}

class FuelControlApp extends StatelessWidget {
  const FuelControlApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Abastecimento',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<Vehicle> _vehicles = [];
  final List<FuelRecord> _records = [];

  void _navigateToVehicleManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleManagementPage(
          vehicles: _vehicles,
          onVehicleChanged: (updatedVehicles) {
            setState(() {
              _vehicles.clear();
              _vehicles.addAll(updatedVehicles);
            });
          },
        ),
      ),
    );
  }

  void _navigateToFuelRecords() {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um veículo primeiro')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FuelRecordsPage(
          vehicles: _vehicles,
          records: _records,
          onRecordAdded: (record) {
            setState(() {
              _records.add(record);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Abastecimento'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.car_rental),
              label: const Text('Gerenciar Veículos'),
              onPressed: _navigateToVehicleManagement,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Registros de Abastecimento'),
              onPressed: _navigateToFuelRecords,
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleManagementPage extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(List<Vehicle>) onVehicleChanged;

  const VehicleManagementPage({
    Key? key,
    required this.vehicles,
    required this.onVehicleChanged,
  }) : super(key: key);

  @override
  VehicleManagementPageState createState() => VehicleManagementPageState();
}

class VehicleManagementPageState extends State<VehicleManagementPage> {
  late List<Vehicle> _vehicles;

  @override
  void initState() {
    super.initState();
    _vehicles = List.from(widget.vehicles);
  }

  void _showVehicleDialog({Vehicle? vehicle}) {
    final nameController = TextEditingController(text: vehicle?.name ?? '');
    final modelController = TextEditingController(text: vehicle?.model ?? '');
    final yearController = TextEditingController(text: vehicle?.year.toString() ?? '');
    final plateController = TextEditingController(text: vehicle?.licensePlate ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle == null ? 'Novo Veículo' : 'Editar Veículo'),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'Placa'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  modelController.text.isEmpty ||
                  yearController.text.isEmpty ||
                  plateController.text.isEmpty) {
                return;
              }

              final newVehicle = Vehicle(
                id: vehicle?.id ?? DateTime.now().toString(),
                name: nameController.text,
                model: modelController.text,
                year: int.parse(yearController.text),
                licensePlate: plateController.text,
              );

              setState(() {
                if (vehicle == null) {
                  _vehicles.add(newVehicle);
                } else {
                  final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
                  _vehicles[index] = newVehicle;
                }
              });

              widget.onVehicleChanged(_vehicles);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir o veículo ${vehicle.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _vehicles.removeWhere((v) => v.id == vehicle.id);
              });
              widget.onVehicleChanged(_vehicles);
              Navigator.pop(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Veículos'),
      ),
      body: _vehicles.isEmpty
          ? const Center(child: Text('Nenhum veículo cadastrado'))
          : ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return ListTile(
            title: Text(vehicle.name),
            subtitle: Text('${vehicle.model} - ${vehicle.year}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showVehicleDialog(vehicle: vehicle),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteVehicle(vehicle),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FuelRecordsPage extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<FuelRecord> records;
  final Function(FuelRecord) onRecordAdded;

  const FuelRecordsPage({
    Key? key,
    required this.vehicles,
    required this.records,
    required this.onRecordAdded,
  }) : super(key: key);

  @override
  FuelRecordsPageState createState() => FuelRecordsPageState();
}

class FuelRecordsPageState extends State<FuelRecordsPage> {
  Vehicle? _selectedVehicle;
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addRecord() {
    if (_formKey.currentState!.validate() && _selectedVehicle != null) {
      final record = FuelRecord(
        date: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        liters: double.parse(_litersController.text),
        pricePerLiter: double.parse(_priceController.text),
        odometer: double.parse(_odometerController.text),
        vehicle: _selectedVehicle!,
        notes: _notesController.text,
      );

      widget.onRecordAdded(record);

      _clearForm();
      Navigator.pop(context);
    }
  }

  void _clearForm() {
    _dateController.clear();
    _litersController.clear();
    _priceController.clear();
    _odometerController.clear();
    _notesController.clear();
    _selectedVehicle = null;
  }

  void _showAddDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: const Text('Novo Abastecimento'),
    content: SingleChildScrollView(
    child: Form(
    key: _formKey,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    DropdownButtonFormField<Vehicle>(
    value: _selectedVehicle,
    decoration: const InputDecoration(labelText: 'Selecione o Veículo'),
    items: widget.vehicles
        .map((vehicle) => DropdownMenuItem(
    value: vehicle,
    child: Text('${vehicle.name} - ${vehicle.licensePlate}'),
    ))
        .toList(),
    onChanged: (vehicle) => setState(() => _selectedVehicle = vehicle),
    validator: (value) => value == null ? 'Selecione um veículo' : null,
    ),
    TextFormField(
    controller: _dateController,
    decoration: const InputDecoration(labelText: 'Data (dd/mm/aaaa)'),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Por favor, insira a data';
    }
    try {
    DateFormat('dd/MM/yyyy').parse(value);
    } catch (e) {
    return 'Data inválida';
    }
    return null;
    },
    ),
    TextFormField(
    controller: _litersController,
    decoration: const InputDecoration(labelText: 'Litros'),
    keyboardType: TextInputType.number,
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Por favor, insira a quantidade';
    }
    if (double.tryParse(value) == null) {
    return 'Valor inválido';
    }
    return null;
    },
    ),
    TextFormField(
    controller: _priceController,
    decoration: const InputDecoration(labelText: 'Preço por litro'),
    keyboardType: TextInputType.number,
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Por favor, insira o preço';
    }
    if (double.tryParse(value) == null) {
    return 'Valor inválido';
    }
    return null;
    },
    ),
      TextFormField(
        controller: _odometerController,
        decoration: const InputDecoration(labelText: 'Quilometragem'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira a quilometragem';
          }
          if (double.tryParse(value) == null) {
            return 'Valor inválido';
          }
          return null;
        },
      ),
      TextFormField(
        controller: _notesController,
        decoration: const InputDecoration(labelText: 'Observações'),
        maxLines: 2,
      ),
    ],
    ),
    ),
    ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _addRecord,
              child: const Text('Salvar'),
            ),
          ],
        ),
    );
  }

  Widget _buildConsumptionStats() {
    if (widget.records.isEmpty) return const SizedBox.shrink();


    final recordsByVehicle = <String, List<FuelRecord>>{};
    for (var record in widget.records) {
      recordsByVehicle.putIfAbsent(record.vehicle.id, () => []).add(record);
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas de Consumo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recordsByVehicle.entries.map((entry) {
              final vehicleRecords = entry.value;
              final stats = FuelConsumptionStats(vehicleRecords);
              final vehicle = vehicleRecords.first.vehicle;
              final avgConsumption = stats.getAverageConsumption();
              final latestConsumption = stats.getLatestConsumption();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (avgConsumption != null)
                      Text('Média geral: ${avgConsumption.toStringAsFixed(2)} km/l'),
                    if (latestConsumption != null)
                      Text('Último consumo: ${latestConsumption.toStringAsFixed(2)} km/l'),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, int index) {
    final record = widget.records[index];
    final previousRecord = index < widget.records.length - 1 ?
    widget.records.where((r) => r.vehicle.id == record.vehicle.id && r.date.isBefore(record.date))
        .fold<FuelRecord?>(null, (prev, curr) => prev == null || curr.date.isAfter(prev.date) ? curr : prev)
        : null;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(record.vehicle.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${DateFormat('dd/MM/yyyy').format(record.date)}'),
            Text('Litros: ${record.liters.toStringAsFixed(2)}'),
            Text('Preço/L: R\$ ${record.pricePerLiter.toStringAsFixed(2)}'),
            Text('Total: R\$ ${record.totalCost.toStringAsFixed(2)}'),
            Text('Km: ${record.odometer.toStringAsFixed(0)}'),
            if (previousRecord != null) Text(
                'Consumo: ${FuelRecord.calculateConsumption(record, previousRecord).toStringAsFixed(2)} km/l'
            ),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text('Obs: ${record.notes}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Abastecimento'),
      ),
      body: widget.records.isEmpty
          ? const Center(child: Text('Nenhum registro de abastecimento'))
          : Column(
        children: [
          _buildConsumptionStats(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.records.length,
              itemBuilder: _buildRecordItem,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}