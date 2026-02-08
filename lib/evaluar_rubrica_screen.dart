import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'auth_helper.dart';
import 'ejecutar_evaluacion_screen.dart';
import 'tutorial_helper.dart';

const Color _primaryColor = Color(0xFF3949AB);
const Color _accentColor = Color(0xFF4FC3F7);
const Color _backgroundColor = Color(0xFFD1D9E6);
const Color _buttonSuccessColor = Color(0xFF2E7D32);
const Color _importSuccessColor = Color(0xFFC8E6C9);

class EvaluarRubricaScreen extends StatefulWidget {
  final String rubricaId;
  final String nombreRubrica;

  const EvaluarRubricaScreen({
    super.key,
    required this.rubricaId,
    required this.nombreRubrica
  });

  @override
  State<EvaluarRubricaScreen> createState() => _EvaluarRubricaScreenState();
}

class _EvaluarRubricaScreenState extends State<EvaluarRubricaScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final GlobalKey _keyImportar = GlobalKey();
  final GlobalKey _keySelector = GlobalKey();
  final GlobalKey _keyManual = GlobalKey();
  final GlobalKey _keyBotonEvaluar = GlobalKey();

  bool _cargando = false;
  final String __app_id = 'rubrica_evaluator';

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _dniCtrl = TextEditingController();

  final FocusNode _nombreFocus = FocusNode();
  final FocusNode _apellidoFocus = FocusNode();
  final FocusNode _dniFocus = FocusNode();

  List<Map<String, String>> _estudiantesExcel = [];
  Map<String, String>? _estudianteSeleccionado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _nombreFocus.requestFocus();
        });
      }
    });

    _nombreCtrl.addListener(() => setState(() {}));
    _apellidoCtrl.addListener(() => setState(() {}));
    _dniCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarTutorial());
  }

  void _iniciarTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'EVALUAR_RUBRICA',
      force: force,
      keys: {
        'importar': _keyImportar,
        'selector': _keySelector,
        'tab_manual': _keyManual,
        'btn_comenzar': _keyBotonEvaluar,
      },
    );
  }

  bool get _esFormularioValido {
    if (_tabController.index == 0) {
      return _estudianteSeleccionado != null;
    } else {
      return _nombreCtrl.text.trim().isNotEmpty &&
          _apellidoCtrl.text.trim().isNotEmpty &&
          _dniCtrl.text.replaceAll('.', '').length == 8;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glowController.dispose();
    _nombreCtrl.dispose(); _apellidoCtrl.dispose(); _dniCtrl.dispose();
    _nombreFocus.dispose(); _apellidoFocus.dispose(); _dniFocus.dispose();
    super.dispose();
  }

  void _descargarPlantilla() {
    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheet = excel['Sheet1'];
    var headerStyle = excel_lib.CellStyle(
      bold: true,
      fontColorHex: excel_lib.ExcelColor.fromHexString("#FFFFFF"),
      backgroundColorHex: excel_lib.ExcelColor.fromHexString("#3949AB"),
    );
    List<String> headers = ["DNI", "NOMBRE", "APELLIDO"];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      final content = Uint8List.fromList(fileBytes);
      final blob = html.Blob([content], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute("download", "plantilla.xlsx")..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _importarExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      var excel = excel_lib.Excel.decodeBytes(result.files.first.bytes!);
      List<Map<String, String>> temporal = [];
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null || sheet.maxRows < 2) continue;
        int idxDni = -1, idxNom = -1, idxApe = -1;
        var header = sheet.rows.first;
        for (int i = 0; i < header.length; i++) {
          String val = header[i]?.value.toString().toUpperCase() ?? "";
          if (val.contains("DNI")) idxDni = i;
          if (val.contains("NOMBRE")) idxNom = i;
          if (val.contains("APELLIDO")) idxApe = i;
        }
        if (idxDni != -1 && idxNom != -1 && idxApe != -1) {
          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            if (row[idxDni] == null) continue;
            temporal.add({
              'dni': row[idxDni]?.value.toString() ?? "",
              'nombre': row[idxNom]?.value.toString() ?? "",
              'apellido': row[idxApe]?.value.toString() ?? "",
            });
          }
        }
      }

      setState(() {
        _estudiantesExcel = temporal;
        _estudianteSeleccionado = null;
      });

      if (temporal.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Importación exitosa! ${temporal.length} alumnos cargados."),
            backgroundColor: _buttonSuccessColor,
            duration: const Duration(seconds: 2),
          ),
        );

        _glowController.repeat(reverse: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _glowController.stop();
          if (mounted) _glowController.reset();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildCustomAppBar(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: 500,
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 480,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildExcelView(),
                          _buildManualView(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 5),
      decoration: const BoxDecoration(
        color: _primaryColor,
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Column(
        children: [
          // CABECERA CON CENTRADO ABSOLUTO USANDO STACK
          SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icono de volver a la izquierda
                Positioned(
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // TÍTULO CENTRADO
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 110), // Espacio para que no choque con botones laterales
                    child: Text(
                      widget.nombreRubrica.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Acciones a la derecha con margen para evitar recorte
                Positioned(
                  right: 15,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TutorialHelper.helpButton(context, () => _iniciarTutorial(force: true)),
                      const SizedBox(width: 5),
                      AuthHelper.logoutButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            indicatorColor: _accentColor,
            indicatorWeight: 4,
            labelPadding: const EdgeInsets.symmetric(vertical: 8),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            tabs: [
              const Tab(icon: Icon(Icons.table_chart, size: 24), text: "LISTA EXCEL"),
              Tab(
                  key: _keyManual,
                  icon: const Icon(Icons.person_add, size: 24),
                  text: "CARGA MANUAL"
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcelView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Icon(Icons.file_present_rounded, size: 60, color: _primaryColor),
              const SizedBox(height: 10),
              Row(
                key: _keyImportar,
                children: [
                  Expanded(child: _buildSecondaryButton("PLANTILLA", Icons.download, _descargarPlantilla)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPrimaryButton("IMPORTAR", Icons.upload_file, _importarExcel)),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    key: _keySelector,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(_glowController.isAnimating ? 0.6 : 0),
                          blurRadius: _glowAnimation.value,
                        )
                      ],
                    ),
                    child: child,
                  );
                },
                child: _buildStudentDropdown(),
              ),
            ],
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildManualView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const Text("DATOS DEL ESTUDIANTE",
                  style: TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 18)),
              const SizedBox(height: 10),
              _buildStyledField(
                controller: _nombreCtrl,
                label: 'Nombre',
                icon: Icons.person_outline,
                focusNode: _nombreFocus,
                textInputAction: TextInputAction.next,
              ),
              _buildStyledField(
                controller: _apellidoCtrl,
                label: 'Apellido',
                icon: Icons.person_outline,
                focusNode: _apellidoFocus,
                textInputAction: TextInputAction.next,
              ),
              _buildStyledField(
                controller: _dniCtrl,
                label: 'DNI (ej: 11.222.333)',
                icon: Icons.badge_outlined,
                focusNode: _dniFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.go,
                maxLength: 10,
                formatters: [FilteringTextInputFormatter.digitsOnly, DniInputFormatter()],
                onSubmitted: (_) => _comenzar(),
              ),
            ],
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
          prefixIcon: Icon(icon, color: _primaryColor, size: 22),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.black54, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: _primaryColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final bool activo = _esFormularioValido && !_cargando;
    return ElevatedButton(
      key: _keyBotonEvaluar,
      onPressed: activo ? _comenzar : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonSuccessColor,
        disabledBackgroundColor: Colors.grey.shade400,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: activo ? 6 : 0,
      ),
      child: _cargando
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text("COMENZAR EVALUACIÓN",
          style: TextStyle(
              color: activo ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.1
          )),
    );
  }

  Widget _buildStudentDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: _estudiantesExcel.isNotEmpty ? _importSuccessColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _estudiantesExcel.isNotEmpty ? _buttonSuccessColor : Colors.black,
            width: 1.8
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, String>>(
          isExpanded: true,
          value: _estudianteSeleccionado,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down_circle, color: _primaryColor, size: 24),
          hint: const Text("Seleccionar alumno...",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          items: _estudiantesExcel.map((est) {
            return DropdownMenuItem(
              value: est,
              child: Text("${est['nombre']} ${est['apellido']} (${est['dni']})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _estudianteSeleccionado = val),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor, width: 2.0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _comenzar() async {
    if (!_esFormularioValido || _cargando) return;
    setState(() => _cargando = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    String nombreEstudiante;
    if (_tabController.index == 0) {
      nombreEstudiante = "${_estudianteSeleccionado!['nombre']} ${_estudianteSeleccionado!['apellido']}";
    } else {
      nombreEstudiante = "${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}";
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('artifacts/$__app_id/users/$userId/rubricas')
          .doc(widget.rubricaId)
          .get();

      if (!doc.exists) throw "La rúbrica no existe.";

      final rubricaCompleta = doc.data() as Map<String, dynamic>;

      if (!mounted) return;

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EjecutarEvaluacionScreen(
                rubricaId: widget.rubricaId,
                nombre: widget.nombreRubrica,
                estudiante: nombreEstudiante,
                rubricaData: rubricaCompleta,
              )
          )
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}

class DniInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 4) && i != text.length - 1) buffer.write('.');
    }
    final formattedText = buffer.toString();
    return newValue.copyWith(text: formattedText, selection: TextSelection.collapsed(offset: formattedText.length));
  }
}