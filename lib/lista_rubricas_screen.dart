import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'evaluar_rubrica_screen.dart';
import 'editar_rubrica_screen.dart';
import 'editar_rubrica_difusa_screen.dart';
import 'auth_helper.dart';
import 'tutorial_helper.dart';

const String __app_id = 'rubrica_evaluator';
const Color blueCrear = Colors.blue;
const String _pdfUrl = 'https://drive.google.com/file/d/1YqbBuRZw82F3D2Jh0DhdNtyNed3aGQiz/view?usp=sharing';

class ListaRubricasScreen extends StatefulWidget {
  const ListaRubricasScreen({super.key});

  @override
  State<ListaRubricasScreen> createState() => _ListaRubricasScreenState();
}

class _ListaRubricasScreenState extends State<ListaRubricasScreen> {
  DateTime? _fechaFiltro;
  String _filtroNombre = "";
  int? _tipoRubricaFiltro; // null: sin selección, 1: Tradicional, 2: Difusa

  final GlobalKey _keyBuscador = GlobalKey();
  final GlobalKey _keyFiltroFecha = GlobalKey();
  final GlobalKey _keyTipoRubrica = GlobalKey();
  final GlobalKey _keyPrimeraCard = GlobalKey();

  Future<void> _abrirManualPdf() async {
    final Uri uri = Uri.parse(_pdfUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el manual de usuario.')),
        );
      }
    }
  }

  String _normalizarTexto(String texto) {
    var conAcentos = 'ÁÉÍÓÚáéíóúàèìòùÀÈÌÒÙâêîôûÄËÏÖÜñÑ';
    var sinAcentos = 'AEIOUaeiouaeiouAEIOUaeiouAEIOUnN';
    String salida = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return salida.toLowerCase().trim();
  }

  void _lanzarTutorial({bool force = false}) {
    TutorialHelper().showTutorial(
      context: context,
      pageId: 'LISTA_RUBRICAS',
      keys: {
        'buscador': _keyBuscador,
        'tipo_rubrica': _keyTipoRubrica,
        'filtro_fecha': _keyFiltroFecha,
        'primera_card': _keyPrimeraCard,
      },
      force: force,
    );
  }

  int _determinarTipoRubrica(Map<String, dynamic> data) {
    dynamic tipoRaw = data['tipoRubrica'];
    if (tipoRaw != null) {
      if (tipoRaw is int) return tipoRaw;
      if (tipoRaw is num) return tipoRaw.toInt();
      if (tipoRaw is String) {
        int? parsed = int.tryParse(tipoRaw);
        if (parsed != null) return parsed;
      }
    }

    final criterios = (data['criterios'] as List?) ?? [];
    for (var c in criterios) {
      if (c is Map && c['descriptores'] is List) {
        for (var desc in (c['descriptores'] as List)) {
          if (desc is Map && (desc['analiticos'] != null || desc['puntos'] != null)) {
            return 2;
          }
        }
      }
    }

    return 1;
  }

  double _obtenerPeso(dynamic item) {
    if (item is Map) {
      final val = item['porcentaje'] ?? item['peso'] ?? item['porcentajePeso'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }

  List<String> _validarRubrica(Map<String, dynamic> data) {
    List<String> errores = [];
    final listCriterios = (data['criterios'] as List?) ?? [];

    // 1. Validar Criterios y Porcentajes
    if (listCriterios.isEmpty) {
      errores.add("Debe existir al menos un criterio de evaluación.");
    } else {
      double sumaPesos = 0;
      bool tienePesoCeroOInvalido = false;

      for (var c in listCriterios) {
        double peso = _obtenerPeso(c);
        if (peso <= 0) {
          tienePesoCeroOInvalido = true;
        }
        sumaPesos += peso;
      }

      if (tienePesoCeroOInvalido) {
        errores.add("Cada criterio debe tener un porcentaje asignado strictly mayor a 0%.");
      }

      if (sumaPesos < 99.0 || sumaPesos > 100.1) {
        errores.add("La suma total de los porcentajes debe dar exactamente 100% (Suma actual: ${sumaPesos.toStringAsFixed(1)}%).");
      }
    }

    // 2. Validar Niveles Globales / Contextos
    Set<String> nombresNiveles = {};
    List listNiveles = (data['niveles'] ?? data['nivelesGlobales'] as List?) ?? [];

    if (listNiveles.isNotEmpty) {
      for (var n in listNiveles) {
        String nombre = "";
        if (n is Map) {
          nombre = (n['contexto'] ?? n['nombre'] ?? n['titulo'] ?? n['etiqueta'] ?? '').toString();
        } else {
          nombre = n.toString();
        }
        if (nombre.trim().isNotEmpty) {
          nombresNiveles.add(nombre.trim());
        }
      }
    } else if (listCriterios.isNotEmpty) {
      for (var c in listCriterios) {
        if (c is Map && c['descriptores'] is List) {
          for (var desc in (c['descriptores'] as List)) {
            if (desc is Map) {
              final analiticos = desc['analiticos'] as List?;
              if (analiticos != null && analiticos.isNotEmpty) {
                for (var a in analiticos) {
                  if (a is Map) {
                    String ctx = (a['contexto'] ?? a['nombre'] ?? '').toString().trim();
                    if (ctx.isNotEmpty) nombresNiveles.add(ctx);
                  }
                }
              } else {
                String ctx = (desc['contexto'] ?? desc['nombre'] ?? '').toString().trim();
                if (ctx.isNotEmpty) nombresNiveles.add(ctx);
              }
            }
          }
        }
      }
    }

    if (nombresNiveles.isEmpty) {
      errores.add("Debe haber al menos un nivel global de evaluación definido.");
    }

    // 3. Validar Descriptores por Criterio
    if (listCriterios.isNotEmpty) {
      bool descriptoresIncompletos = false;
      bool contieneTextoPlantilla = false;

      for (var c in listCriterios) {
        if (c is Map) {
          final descs = c['descriptores'];
          if (descs == null || (descs is List && descs.isEmpty)) {
            descriptoresIncompletos = true;
            break;
          }

          int cantidadTextosValidos = 0;

          if (descs is List) {
            for (var item in descs) {
              if (item is Map) {
                final analiticos = item['analiticos'] as List?;
                if (analiticos != null && analiticos.isNotEmpty) {
                  for (var a in analiticos) {
                    if (a is Map) {
                      String txt = (a['texto'] ?? a['descriptor'] ?? a['descripcion'] ?? '').toString().trim();
                      if (txt.toLowerCase() == 'descripción del nivel' || txt.toLowerCase() == 'descripcion del nivel') {
                        contieneTextoPlantilla = true;
                      } else if (txt.isNotEmpty) {
                        cantidadTextosValidos++;
                      }
                    }
                  }
                } else {
                  String txt = (item['texto'] ?? item['descriptor'] ?? item['descripcion'] ?? '').toString().trim();
                  if (txt.toLowerCase() == 'descripción del nivel' || txt.toLowerCase() == 'descripcion del nivel') {
                    contieneTextoPlantilla = true;
                  } else if (txt.isNotEmpty) {
                    cantidadTextosValidos++;
                  }
                }
              } else {
                String txt = item.toString().trim();
                if (txt.toLowerCase() == 'descripción del nivel' || txt.toLowerCase() == 'descripcion del nivel') {
                  contieneTextoPlantilla = true;
                } else if (txt.isNotEmpty) {
                  cantidadTextosValidos++;
                }
              }
            }
          } else if (descs is Map) {
            for (var val in descs.values) {
              String txt = "";
              if (val is Map) {
                txt = (val['texto'] ?? val['descriptor'] ?? val['descripcion'] ?? '').toString().trim();
              } else {
                txt = val.toString().trim();
              }
              if (txt.toLowerCase() == 'descripción del nivel' || txt.toLowerCase() == 'descripcion del nivel') {
                contieneTextoPlantilla = true;
              } else if (txt.isNotEmpty) {
                cantidadTextosValidos++;
              }
            }
          } else {
            descriptoresIncompletos = true;
            break;
          }

          int minRequerido = nombresNiveles.isNotEmpty ? nombresNiveles.length : 1;
          if (cantidadTextosValidos < minRequerido) {
            descriptoresIncompletos = true;
            break;
          }
        } else {
          descriptoresIncompletos = true;
          break;
        }
      }

      if (contieneTextoPlantilla) {
        errores.add("Debes personalizar las descripciones iniciales ('Descripción del nivel') de la plantilla.");
      } else if (descriptoresIncompletos) {
        errores.add("Cada criterio debe tener asociados descriptores completos y no vacíos para todos los niveles globales.");
      }
    }

    return errores;
  }

  void _mostrarDialogoCondicionesFaltantes(List<String> errores) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Condiciones Incompletas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "La rúbrica seleccionada no cumple con las siguientes condiciones para ser evaluada:",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...errores.map(
                    (err) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
                        child: Text(err, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ACEPTAR",
              style: TextStyle(fontWeight: FontWeight.bold, color: blueCrear),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesCentrales(Map<String, dynamic> data, String docId) {
    final GlobalKey keyEvaluar = GlobalKey();
    final GlobalKey keyEditar = GlobalKey();
    final GlobalKey keyEliminar = GlobalKey();

    int tipoReal = _determinarTipoRubrica(data);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(data['nombre'] ?? 'Opciones',
              textAlign: TextAlign.center,
              style: const TextStyle(color: blueCrear, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: keyEvaluar,
                leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.play_arrow, color: Colors.green)),
                title: const Text("Evaluar"),
                onTap: () {
                  Navigator.pop(context);
                  final errores = _validarRubrica(data);

                  if (errores.isNotEmpty) {
                    _mostrarDialogoCondicionesFaltantes(errores);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluarRubricaScreen(
                          rubricaId: docId,
                          nombreRubrica: data['nombre'] ?? 'Sin nombre',
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                key: keyEditar,
                leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.edit, color: Colors.blue)),
                title: const Text("Editar"),
                onTap: () {
                  Navigator.pop(context);
                  if (tipoReal == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarRubricaDifusaScreen(
                          rubricaId: docId,
                          nombreInicial: data['nombre'] ?? '',
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarRubricaScreen(
                          rubricaId: docId,
                          nombreInicial: data['nombre'] ?? '',
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                key: keyEliminar,
                leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), child: const Icon(Icons.delete, color: Colors.red)),
                title: const Text("Eliminar"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminacion(docId, data['nombre'] ?? '');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmarEliminacion(String docId, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar"),
        content: Text("¿Borrar '$nombre'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("SÍ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFB0BEC5),
      appBar: AppBar(
        title: const Text("Mis Rúbricas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: blueCrear,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: blueCrear,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
              ),
              onPressed: _abrirManualPdf,
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: const Text(
                'MANUAL DE USUARIO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Container(
            key: _keyFiltroFecha,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: _fechaFiltro ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (picked != null) setState(() => _fechaFiltro = picked);
              },
              icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              label: const Text("Filtrar por Fecha", style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
          if (_fechaFiltro != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fechaFiltro = null)),
          TutorialHelper.helpButton(context, () async {
            await TutorialHelper().resetTutorials(['LISTA_RUBRICAS', 'OPCIONES_RUBRICA']);
            _lanzarTutorial(force: true);
          }),
          AuthHelper.logoutButton(context),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: blueCrear,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))
            ),
            child: Column(
              children: [
                TextField(
                  key: _keyBuscador,
                  decoration: InputDecoration(
                    hintText: "Buscar rúbrica...",
                    prefixIcon: const Icon(Icons.search, color: blueCrear),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _filtroNombre = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: _keyTipoRubrica,
                  value: _tipoRubricaFiltro,
                  hint: const Text("SELECCIONE EL TIPO DE RÚBRICA", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('RÚBRICA TRADICIONAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('RÚBRICA DIFUSA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tipoRubricaFiltro = val;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _tipoRubricaFiltro == null
                ? const Center(
              child: Text(
                "Por favor, seleccione un tipo de rúbrica para continuar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
            )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('artifacts/$__app_id/users/$userId/rubricas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;

                docs = docs.where((d) {
                  int tipoDoc = _determinarTipoRubrica(d.data());
                  return tipoDoc == _tipoRubricaFiltro;
                }).toList();

                if (_filtroNombre.isNotEmpty) {
                  final busca = _normalizarTexto(_filtroNombre);
                  docs = docs.where((d) => _normalizarTexto(d.data()['nombre'] ?? "").contains(busca)).toList();
                }
                if (_fechaFiltro != null) {
                  docs = docs.where((d) {
                    final f = (d.data()['fechaCreacion'] as Timestamp?)?.toDate();
                    return f != null && f.day == _fechaFiltro!.day && f.month == _fechaFiltro!.month && f.year == _fechaFiltro!.year;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No se encontraron rúbricas para esta selección.",
                      style: TextStyle(fontSize: 15, color: Colors.blueGrey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final f = (data['fechaCreacion'] as Timestamp?)?.toDate();
                    final fechaLabel = f != null ? DateFormat('dd/MM/yyyy').format(f) : "---";
                    return Card(
                      key: index == 0 ? _keyPrimeraCard : null,
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: blueCrear.withOpacity(0.1), child: const Icon(Icons.assignment, color: blueCrear)),
                        title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Creada: $fechaLabel"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _mostrarOpcionesCentrales(data, docs[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}