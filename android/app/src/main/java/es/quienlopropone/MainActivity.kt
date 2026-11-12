package es.quienlopropone

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { Tema { App() } }
    }
}

@Composable
fun Tema(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = if (isSystemInDarkTheme()) darkColorScheme() else lightColorScheme()) {
        Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) { content() }
    }
}

fun colorDe(p: Partido): Color = when (p) {
    Partido.ERC -> Color(0xFFE8A317)
    Partido.PP -> Color(0xFF1D6FB8)
    Partido.VOX -> Color(0xFF4E9A23)
}

private val VERDE = Color(0xFF2E7D32)
private val ROJO = Color(0xFFC62828)

/** «del PP», «de ERC», «de VOX». */
fun Partido.conDe() = if (this == Partido.PP) "del PP" else "de $sigla"

sealed interface Pantalla {
    data object Inicio : Pantalla
    data object ConfigVF : Pantalla
    class Jugando(val partida: Partida) : Pantalla
    class Resultado(val partida: Partida) : Pantalla
}

@Composable
fun App(inicial: Pantalla = Pantalla.Inicio) {
    val context = LocalContext.current
    val todas = remember { Repositorio.cargar(context) }
    var pantalla by remember { mutableStateOf(inicial) }

    BackHandler(enabled = pantalla != Pantalla.Inicio) { pantalla = Pantalla.Inicio }

    Column(
        Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        when (val p = pantalla) {
            Pantalla.Inicio -> Inicio(
                compartidas = todas.count { it.compartida },
                onAdivina = { pantalla = Pantalla.Jugando(Partida.adivina(todas)) },
                onVerdaderoFalso = { pantalla = Pantalla.ConfigVF },
            )
            Pantalla.ConfigVF -> ConfigVF(
                onVolver = { pantalla = Pantalla.Inicio },
                onEmpezar = { partido, n -> pantalla = Pantalla.Jugando(Partida.verdaderoFalso(todas, partido, n)) },
            )
            is Pantalla.Jugando -> Jugando(
                partida = p.partida,
                todas = todas,
                onSalir = { pantalla = Pantalla.Inicio },
                onFin = { pantalla = Pantalla.Resultado(p.partida) },
            )
            is Pantalla.Resultado -> Resultado(
                partida = p.partida,
                onOtra = { pantalla = Pantalla.Jugando(p.partida.otraIgual(todas)) },
                onMenu = { pantalla = Pantalla.Inicio },
            )
        }
    }
}

// ---------------------------------------------------------------- Inicio

@Composable
private fun Inicio(compartidas: Int, onAdivina: () -> Unit, onVerdaderoFalso: () -> Unit) {
    Text("¿Quién lo propone?", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    Text(
        "Pon a prueba lo que sabes de los programas electorales de ERC, PP y VOX.",
        style = MaterialTheme.typography.bodyLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(Modifier.height(4.dp))
    TarjetaModo(
        titulo = "Adivina el partido",
        texto = "10 propuestas de los tres partidos, repartidas a partes iguales. Para cada una, elige quién la propone.",
        boton = "Jugar",
        onClick = onAdivina,
    )
    TarjetaModo(
        titulo = "¿Verdadero o falso?",
        texto = "Elige un partido y responde si cada propuesta es suya o no. Tú decides cuántas: 10, 20 o 50.",
        boton = "Elegir partido",
        onClick = onVerdaderoFalso,
    )
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
    ) {
        Text(
            "🤝 $compartidas propuestas aparecen, con otras palabras, en el programa de más de un partido. " +
                "En el juego, cualquiera de ellos cuenta como respuesta correcta.",
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(16.dp),
        )
    }
    Spacer(Modifier.height(8.dp))
    Fuentes()
}

@Composable
private fun TarjetaModo(titulo: String, texto: String, boton: String, onClick: () -> Unit) {
    ElevatedCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(titulo, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(texto, style = MaterialTheme.typography.bodyMedium)
            Button(onClick = onClick, modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp)) { Text(boton, fontSize = 16.sp) }
        }
    }
}

@Composable
private fun Fuentes() {
    Text(
        "Fuentes: programas de ERC y PP para las elecciones generales de 2026 y de VOX para las " +
            "autonómicas de Castilla y León 2026. Los títulos de ERC están traducidos del catalán.",
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

// ---------------------------------------------------------------- Configuración V/F

@Composable
private fun ConfigVF(onVolver: () -> Unit, onEmpezar: (Partido, Int) -> Unit) {
    var partido by remember { mutableStateOf<Partido?>(null) }
    var n by remember { mutableIntStateOf(10) }

    TextButton(onClick = onVolver, contentPadding = PaddingValues(0.dp)) { Text("← Volver") }
    Text("¿Verdadero o falso?", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
    Text(
        "La mitad de las propuestas serán del partido que elijas y la otra mitad, de los otros dos.",
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )

    Text("1. Elige un partido", style = MaterialTheme.typography.titleMedium)
    Partido.entries.forEach { p ->
        val sel = partido == p
        OutlinedCard(
            onClick = { partido = p },
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.outlinedCardColors(
                containerColor = if (sel) colorDe(p) else MaterialTheme.colorScheme.surface,
            ),
            border = CardDefaults.outlinedCardBorder().copy(width = 2.dp, brush = androidx.compose.ui.graphics.SolidColor(colorDe(p))),
        ) {
            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    p.sigla, fontSize = 22.sp, fontWeight = FontWeight.Bold,
                    color = if (sel) Color.White else colorDe(p), modifier = Modifier.width(72.dp),
                )
                Text(
                    if (p == Partido.VOX) "Autonómicas de Castilla y León" else p.nombre,
                    color = if (sel) Color.White else MaterialTheme.colorScheme.onSurface,
                )
            }
        }
    }

    Text("2. ¿Cuántas preguntas?", style = MaterialTheme.typography.titleMedium)
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
        listOf(10, 20, 50).forEachIndexed { i, valor ->
            SegmentedButton(
                selected = n == valor,
                onClick = { n = valor },
                shape = SegmentedButtonDefaults.itemShape(i, 3),
            ) { Text("$valor") }
        }
    }

    Button(
        onClick = { partido?.let { onEmpezar(it, n) } },
        enabled = partido != null,
        modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
    ) { Text(if (partido == null) "Elige un partido" else "Empezar: $n preguntas sobre ${partido!!.sigla}", fontSize = 16.sp) }
}

// ---------------------------------------------------------------- Partida

@Composable
private fun Jugando(partida: Partida, todas: List<Iniciativa>, onSalir: () -> Unit, onFin: () -> Unit) {
    var indice by remember(partida) { mutableIntStateOf(0) }
    // Respuesta dada a la pregunta actual: un Partido (modo adivina) o un Boolean (modo V/F).
    var respuesta by remember(partida) { mutableStateOf<Any?>(null) }
    var verDetalle by remember(partida) { mutableStateOf(false) }

    val total = partida.preguntas.size
    val actual = partida.preguntas[indice]

    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        TextButton(onClick = onSalir, contentPadding = PaddingValues(0.dp)) { Text("← Salir") }
        Spacer(Modifier.weight(1f))
        Text("Aciertos: ${partida.aciertos}", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
    }
    Text("Pregunta ${indice + 1} de $total", style = MaterialTheme.typography.labelLarge)
    LinearProgressIndicator(
        progress = { (indice + if (respuesta != null) 1 else 0) / total.toFloat() },
        modifier = Modifier.fillMaxWidth(),
    )

    ElevatedCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(actual.tema.uppercase(), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
            Text(actual.titulo, fontSize = 21.sp, lineHeight = 28.sp, fontWeight = FontWeight.Medium)
        }
    }

    when (partida.modo) {
        Modo.ADIVINA -> {
            Text("¿De qué partido es?", style = MaterialTheme.typography.titleMedium)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Partido.entries.forEach { p ->
                    BotonRespuesta(
                        texto = p.sigla, subtitulo = if (p == Partido.VOX) "Castilla y León" else p.nombre,
                        color = colorDe(p),
                        activo = respuesta == null || respuesta == p || p in actual.partidosValidos,
                        modifier = Modifier.weight(1f),
                    ) {
                        if (respuesta == null) { respuesta = p; partida.resultados += partida.corregir(actual, p) }
                    }
                }
            }
        }
        Modo.VERDADERO_FALSO -> {
            val objetivo = partida.partido!!
            Text("¿Es una propuesta ${objetivo.conDe()}?", style = MaterialTheme.typography.titleMedium)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                listOf(true to "Verdadero", false to "Falso").forEach { (valor, texto) ->
                    BotonRespuesta(
                        texto = texto, subtitulo = null,
                        color = if (valor) VERDE else ROJO,
                        activo = respuesta == null || respuesta == valor || valor == partida.esDelPartido(actual),
                        modifier = Modifier.weight(1f),
                    ) {
                        if (respuesta == null) { respuesta = valor; partida.resultados += partida.corregir(actual, valor) }
                    }
                }
            }
        }
    }

    AnimatedVisibility(visible = respuesta != null) {
        Revelacion(actual, todas, acierto = partida.resultados.lastOrNull() == true, verDetalle) { verDetalle = !verDetalle }
    }

    val ultima = indice == total - 1
    Button(
        onClick = {
            if (ultima) onFin() else { indice++; respuesta = null; verDetalle = false }
        },
        enabled = respuesta != null,
        modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
    ) { Text(if (ultima) "Ver resultado" else "Siguiente", fontSize = 16.sp) }
}

@Composable
private fun BotonRespuesta(
    texto: String, subtitulo: String?, color: Color, activo: Boolean,
    modifier: Modifier = Modifier, onClick: () -> Unit,
) {
    Button(
        onClick = onClick,
        enabled = activo,
        colors = ButtonDefaults.buttonColors(
            containerColor = color, contentColor = Color.White,
            disabledContainerColor = color.copy(alpha = 0.25f),
        ),
        contentPadding = PaddingValues(horizontal = 4.dp, vertical = 8.dp),
        modifier = modifier.heightIn(min = 76.dp),
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(texto, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            if (subtitulo != null) Text(subtitulo, fontSize = 11.sp, lineHeight = 13.sp, textAlign = TextAlign.Center)
        }
    }
}

@Composable
private fun Revelacion(actual: Iniciativa, todas: List<Iniciativa>, acierto: Boolean, verDetalle: Boolean, onToggle: () -> Unit) {
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = (if (acierto) VERDE else ROJO).copy(alpha = 0.15f)),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                (if (acierto) "¡Correcto! " else "¡No! ") + "Es ${actual.partido.conDe()}",
                style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                color = if (acierto) VERDE else ROJO,
            )
            Text(
                if (actual.partido == Partido.VOX) "VOX — programa ${actual.partido.programa}"
                else "${actual.partido.nombre} (${actual.partido.sigla}) — programa ${actual.partido.programa}",
                style = MaterialTheme.typography.bodyMedium,
            )
            Text(
                "Medida nº ${actual.numero} · página ${actual.pagina} · ${actual.seccion}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (actual.coincidencias.isNotEmpty()) Coincidencias(actual, todas)
            TextButton(onClick = onToggle, contentPadding = PaddingValues(0.dp)) {
                Text(if (verDetalle) "Ocultar el texto completo" else "Ver el texto completo")
            }
            if (verDetalle) {
                if (actual.original.isNotBlank()) {
                    Text("Texto original (en catalán):", style = MaterialTheme.typography.labelLarge)
                    Text(actual.original, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                }
                if (actual.descripcion.isNotBlank()) Text(actual.descripcion, style = MaterialTheme.typography.bodyMedium)
                else if (actual.original.isBlank()) Text("El programa no añade más detalle.", fontStyle = FontStyle.Italic)
            }
        }
    }
}

@Composable
private fun Coincidencias(actual: Iniciativa, todas: List<Iniciativa>) {
    val iguales = actual.coincidencias.filter { it.igual }
    val parecidas = actual.coincidencias.filter { !it.igual }
    Surface(
        color = MaterialTheme.colorScheme.surface,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            if (iguales.isNotEmpty()) {
                val quienes = iguales.map { it.partido }.distinct()
                Text(
                    "🤝 Propuesta compartida: " + quienes.joinToString(" y ") { if (it == Partido.PP) "el PP" else it.sigla } +
                        (if (quienes.size == 1) " propone" else " proponen") + " lo mismo",
                    style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold,
                )
                iguales.forEach { CoincidenciaFila(it, todas) }
            }
            if (parecidas.isNotEmpty()) {
                Text("Propuestas parecidas en otros programas", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                parecidas.forEach { CoincidenciaFila(it, todas) }
            }
        }
    }
}

@Composable
private fun CoincidenciaFila(c: Coincidencia, todas: List<Iniciativa>) {
    val otra = Repositorio.buscar(todas, c.partido, c.numero)
    Column {
        Text(
            "${c.partido.sigla} · medida nº ${c.numero}",
            style = MaterialTheme.typography.labelMedium, color = colorDe(c.partido), fontWeight = FontWeight.Bold,
        )
        Text("«${otra?.titulo ?: c.resumen}»", style = MaterialTheme.typography.bodyMedium)
    }
}

// ---------------------------------------------------------------- Resultado

@Composable
private fun Resultado(partida: Partida, onOtra: () -> Unit, onMenu: () -> Unit) {
    val context = LocalContext.current
    val total = partida.preguntas.size
    val aciertos = partida.aciertos
    // Lee el récord anterior una vez por partida y, si se ha superado, guarda el nuevo.
    val prefs = remember { context.getSharedPreferences("marcador", Context.MODE_PRIVATE) }
    val recordAnterior = remember(partida) { prefs.getInt(partida.claveRecord, -1) }
    val nuevoRecord = aciertos > recordAnterior && recordAnterior >= 0
    LaunchedEffect(partida) {
        if (aciertos > recordAnterior) runCatching { prefs.edit().putInt(partida.claveRecord, aciertos).apply() }
    }
    val pct = aciertos * 100 / total

    Text(
        when (partida.modo) {
            Modo.ADIVINA -> "Adivina el partido"
            Modo.VERDADERO_FALSO -> "¿Verdadero o falso? · ${partida.partido!!.sigla}"
        },
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    ElevatedCard(Modifier.fillMaxWidth()) {
        Column(
            Modifier.padding(24.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text("$aciertos / $total", fontSize = 48.sp, fontWeight = FontWeight.Bold)
            Text(
                when {
                    pct == 100 -> "¡Perfecto! Te sabes los programas."
                    pct >= 80 -> "¡Muy bien!"
                    pct >= 60 -> "Nada mal."
                    pct >= 40 -> "Regular: hay propuestas que sorprenden."
                    else -> "Los programas tienen más sorpresas de lo que parece."
                },
                style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center,
            )
            Text(
                when {
                    nuevoRecord -> "¡Nuevo récord! (antes: $recordAnterior)"
                    recordAnterior >= 0 -> "Récord: ${maxOf(recordAnterior, aciertos)} / $total"
                    else -> "Primera partida con esta configuración"
                },
                style = MaterialTheme.typography.bodyMedium,
                color = if (nuevoRecord) VERDE else MaterialTheme.colorScheme.onSurfaceVariant,
                fontWeight = if (nuevoRecord) FontWeight.Bold else FontWeight.Normal,
            )
        }
    }

    Button(onClick = onOtra, modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp)) { Text("Jugar otra vez", fontSize = 16.sp) }
    OutlinedButton(onClick = onMenu, modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp)) { Text("Menú principal") }

    val compartidas = partida.preguntas.count { it.compartida }
    if (compartidas > 0) {
        Text(
            "🤝 $compartidas de estas $total propuestas las comparten varios partidos.",
            style = MaterialTheme.typography.bodyMedium,
        )
    }
    Text("Repaso", style = MaterialTheme.typography.titleMedium)
    partida.preguntas.forEachIndexed { i, ini ->
        val ok = partida.resultados.getOrNull(i) == true
        Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(if (ok) "✓" else "✗", color = if (ok) VERDE else ROJO, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Column(Modifier.weight(1f)) {
                Text(ini.titulo, style = MaterialTheme.typography.bodyMedium, maxLines = 3, overflow = TextOverflow.Ellipsis)
                Text(
                    "${ini.partido.sigla} · medida nº ${ini.numero}" +
                        (if (ini.compartida) "  🤝 también " + (ini.partidosValidos - ini.partido).joinToString(", ") { it.sigla } else ""),
                    style = MaterialTheme.typography.labelMedium, color = colorDe(ini.partido), fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}
