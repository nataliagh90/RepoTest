package es.quienlopropone

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
    Partido.PSOE -> Color(0xFFD7141A)
    Partido.PP -> Color(0xFF1D6FB8)
    Partido.VOX -> Color(0xFF4E9A23)
    Partido.FA -> Color(0xFF7B3294)
    Partido.ERC -> Color(0xFFE8A317)
    Partido.JUNTS -> Color(0xFF00A3A1)
}

private val VERDE = Color(0xFF2E7D32)
private val ROJO = Color(0xFFC62828)

/** «del PP», «de ERC», «de VOX». */
fun Partido.conDe() = if (conArticulo.startsWith("el ")) "del " + conArticulo.removePrefix("el ") else "de $conArticulo"

/** true: se muestra «lo esencial» de cada propuesta; false: el título literal del programa. */
val LocalVerEsencial = compositionLocalOf { true }

/** Texto con el que se presenta una propuesta, según la preferencia del jugador. */
@Composable
fun Iniciativa.texto(): String =
    if (LocalVerEsencial.current && esencial.isNotBlank()) LocalTraduccion.current[clave] ?: esencial else titulo

/** «Lo esencial» traducido al idioma elegido (clave «PARTIDO N»); vacío en español. */
val LocalTraduccion = compositionLocalOf<Map<String, String>> { emptyMap() }

sealed interface Pantalla {
    data object Idioma : Pantalla
    data object Bienvenida : Pantalla
    data object Inicio : Pantalla
    data object ConfigVF : Pantalla
    class Jugando(val partida: Partida) : Pantalla
    class Resultado(val partida: Partida) : Pantalla
}

@Composable
fun App(inicial: Pantalla = Pantalla.Inicio, idiomaInicial: Idioma? = null) {
    val context = LocalContext.current
    val todas = remember { Repositorio.cargar(context) }
    var pantalla by remember { mutableStateOf(inicial) }
    val prefs = remember { context.getSharedPreferences("ajustes", Context.MODE_PRIVATE) }
    var verEsencial by remember { mutableStateOf(runCatching { prefs.getBoolean("verEsencial", true) }.getOrDefault(true)) }
    val idiomaGuardado = remember { runCatching { prefs.getString("idioma", null) }.getOrNull() }
    var idioma by remember { mutableStateOf(idiomaInicial ?: Idioma.entries.firstOrNull { it.codigo == idiomaGuardado } ?: Idioma.ES) }
    val bienvenidaVista = remember { runCatching { prefs.getBoolean("bienvenidaVista", false) }.getOrDefault(false) }
    // La primera vez: idioma y después la bienvenida. Quien ya eligió idioma ve la bienvenida una vez.
    LaunchedEffect(Unit) {
        if (idiomaInicial == null && pantalla == Pantalla.Inicio) {
            if (idiomaGuardado == null) pantalla = Pantalla.Idioma
            else if (!bienvenidaVista) pantalla = Pantalla.Bienvenida
        }
    }
    fun terminarBienvenida() {
        runCatching { prefs.edit().putBoolean("bienvenidaVista", true).apply() }
        pantalla = Pantalla.Inicio
    }
    val traduccion = remember(idioma) { Repositorio.traduccion(context, idioma) }

    BackHandler(enabled = pantalla != Pantalla.Inicio) { pantalla = Pantalla.Inicio }

    CompositionLocalProvider(
        LocalVerEsencial provides verEsencial,
        LocalTextos provides textosDe(idioma),
        LocalTraduccion provides traduccion,
    ) { if (pantalla == Pantalla.Bienvenida) Bienvenida(onTerminar = ::terminarBienvenida) else Column(
        Modifier
            .fillMaxSize()
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        when (val p = pantalla) {
            Pantalla.Idioma -> ElegirIdioma(
                actual = idioma,
                onElegir = { i -> idioma = i; runCatching { prefs.edit().putString("idioma", i.codigo).apply() } },
                onContinuar = {
                    runCatching { prefs.edit().putString("idioma", idioma.codigo).apply() }
                    pantalla = if (bienvenidaVista) Pantalla.Inicio else Pantalla.Bienvenida
                },
            )
            Pantalla.Inicio -> Inicio(
                idioma = idioma,
                onIdioma = { pantalla = Pantalla.Idioma },
                onAyuda = { pantalla = Pantalla.Bienvenida },
                compartidas = todas.count { it.compartida },
                verEsencial = verEsencial,
                onVerEsencial = { v -> verEsencial = v; runCatching { prefs.edit().putBoolean("verEsencial", v).apply() } },
                onAdivina = { pantalla = Pantalla.Jugando(Partida.adivina(todas)) },
                onVerdaderoFalso = { pantalla = Pantalla.ConfigVF },
            )
            Pantalla.Bienvenida -> Unit
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
    } }
}

// ---------------------------------------------------------------- Inicio

@Composable
private fun Inicio(
    idioma: Idioma, onIdioma: () -> Unit, onAyuda: () -> Unit,
    compartidas: Int, verEsencial: Boolean, onVerEsencial: (Boolean) -> Unit,
    onAdivina: () -> Unit, onVerdaderoFalso: () -> Unit,
) {
    val t = LocalTextos.current
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(t.titulo, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        TextButton(onClick = onIdioma) { Text("🌐 ${idioma.codigo.uppercase()}") }
        OutlinedIconButton(onClick = onAyuda) {
            Text("?", fontWeight = FontWeight.Bold, fontSize = 18.sp, modifier = Modifier.semantics { contentDescription = t.ayuda })
        }
    }
    Text(
        t.subtitulo(Partido.entries.joinToString(", ") { it.nombre }),
        style = MaterialTheme.typography.bodyLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Text(t.comoVer, style = MaterialTheme.typography.titleSmall)
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
        SegmentedButton(selected = verEsencial, onClick = { onVerEsencial(true) }, shape = SegmentedButtonDefaults.itemShape(0, 2)) {
            Text(t.loEsencial)
        }
        SegmentedButton(selected = !verEsencial, onClick = { onVerEsencial(false) }, shape = SegmentedButtonDefaults.itemShape(1, 2)) {
            Text(t.textoLiteral)
        }
    }
    Text(
        if (verEsencial) t.explicaEsencial else t.explicaLiteral,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
    Spacer(Modifier.height(4.dp))
    TarjetaModo(
        titulo = t.modoAdivina,
        texto = t.modoAdivinaDesc,
        boton = t.jugar,
        onClick = onAdivina,
    )
    TarjetaModo(
        titulo = t.modoVF,
        texto = t.modoVFDesc,
        boton = t.elegirPartido,
        onClick = onVerdaderoFalso,
    )
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
    ) {
        Text(
            t.compartidasInicio(compartidas),
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(16.dp),
        )
    }
    Spacer(Modifier.height(8.dp))
    Fuentes()
}

@Composable
private fun ElegirIdioma(actual: Idioma, onElegir: (Idioma) -> Unit, onContinuar: () -> Unit) {
    val t = LocalTextos.current
    Text("🌐", fontSize = 40.sp)
    Text(t.elegirIdioma, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
    Idioma.entries.forEach { i ->
        val sel = i == actual
        OutlinedCard(
            onClick = { onElegir(i) },
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.outlinedCardColors(
                containerColor = if (sel) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface,
            ),
        ) {
            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                RadioButton(selected = sel, onClick = { onElegir(i) })
                Text(i.nombre, style = MaterialTheme.typography.titleMedium)
            }
        }
    }
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.tertiaryContainer),
    ) {
        Text(t.avisoIA, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.padding(16.dp))
    }
    Button(onClick = onContinuar, modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp)) { Text(t.continuar, fontSize = 16.sp) }
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
        LocalTextos.current.fuentes,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

// ---------------------------------------------------------------- Configuración V/F

@Composable
private fun ConfigVF(onVolver: () -> Unit, onEmpezar: (Partido, Int) -> Unit) {
    val t = LocalTextos.current
    var partido by remember { mutableStateOf<Partido?>(null) }
    var n by remember { mutableIntStateOf(10) }

    TextButton(onClick = onVolver, contentPadding = PaddingValues(0.dp)) { Text(t.volver) }
    Text(t.modoVF, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
    Text(
        t.vfMitad,
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )

    Text(t.paso1, style = MaterialTheme.typography.titleMedium)
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
                    if (p == Partido.VOX) t.autonomicasCyL else p.nombre,
                    color = if (sel) Color.White else MaterialTheme.colorScheme.onSurface,
                )
            }
        }
    }

    Text(t.paso2, style = MaterialTheme.typography.titleMedium)
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
    ) { Text(if (partido == null) t.eligeUnPartido else t.empezar(n, partido!!), fontSize = 16.sp) }
}

// ---------------------------------------------------------------- Partida

@Composable
private fun Jugando(partida: Partida, todas: List<Iniciativa>, onSalir: () -> Unit, onFin: () -> Unit) {
    var indice by remember(partida) { mutableIntStateOf(0) }
    // Respuesta dada a la pregunta actual: un Partido (modo adivina) o un Boolean (modo V/F).
    var respuesta by remember(partida) { mutableStateOf<Any?>(null) }
    var verDetalle by remember(partida) { mutableStateOf(false) }

    val t = LocalTextos.current
    val total = partida.preguntas.size
    val actual = partida.preguntas[indice]

    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        TextButton(onClick = onSalir, contentPadding = PaddingValues(0.dp)) { Text(t.salir) }
        Spacer(Modifier.weight(1f))
        Text(t.aciertos(partida.aciertos), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
    }
    Text(t.pregunta(indice + 1, total), style = MaterialTheme.typography.labelLarge)
    LinearProgressIndicator(
        progress = { (indice + if (respuesta != null) 1 else 0) / total.toFloat() },
        modifier = Modifier.fillMaxWidth(),
    )

    ElevatedCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(t.tema(actual.tema).uppercase(), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
            Text(actual.texto(), fontSize = 21.sp, lineHeight = 28.sp, fontWeight = FontWeight.Medium)
        }
    }

    when (partida.modo) {
        Modo.ADIVINA -> {
            Text(t.deQuePartido, style = MaterialTheme.typography.titleMedium)
            Partido.entries.chunked(3).forEach { fila ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    fila.forEach { p ->
                        BotonRespuesta(
                            texto = p.sigla, subtitulo = t.subtituloBoton(p),
                            color = colorDe(p),
                            estado = estadoBoton(respuesta != null, respuesta == p, p in actual.partidosValidos),
                            modifier = Modifier.weight(1f),
                        ) {
                            if (respuesta == null) { respuesta = p; partida.resultados += partida.corregir(actual, p) }
                        }
                    }
                }
            }
        }
        Modo.VERDADERO_FALSO -> {
            val objetivo = partida.partido!!
            Text(t.esPropuestaDe(objetivo), style = MaterialTheme.typography.titleMedium)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                listOf(true to t.verdadero, false to t.falso).forEach { (valor, texto) ->
                    BotonRespuesta(
                        texto = texto, subtitulo = null,
                        color = if (valor) VERDE else ROJO,
                        estado = estadoBoton(respuesta != null, respuesta == valor, valor == partida.esDelPartido(actual)),
                        modifier = Modifier.weight(1f),
                    ) {
                        if (respuesta == null) { respuesta = valor; partida.resultados += partida.corregir(actual, valor) }
                    }
                }
            }
        }
    }

    AnimatedVisibility(visible = respuesta != null) {
        Revelacion(
            actual, todas, acierto = partida.resultados.lastOrNull() == true, verDetalle,
            elegido = if (partida.modo == Modo.ADIVINA) respuesta as? Partido else partida.partido,
        ) { verDetalle = !verDetalle }
    }

    val ultima = indice == total - 1
    Button(
        onClick = {
            if (ultima) onFin() else { indice++; respuesta = null; verDetalle = false }
        },
        enabled = respuesta != null,
        modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
    ) { Text(if (ultima) t.verResultado else t.siguiente, fontSize = 16.sp) }
}

/** Cómo se muestra un botón de respuesta. */
enum class EstadoBoton { NORMAL, ELEGIDO_OK, ELEGIDO_MAL, CORRECTO_NO_ELEGIDO, INACTIVO }

/** Estado de un botón tras (o antes de) responder. */
fun estadoBoton(respondida: Boolean, elegido: Boolean, correcto: Boolean) = when {
    !respondida -> EstadoBoton.NORMAL
    elegido && correcto -> EstadoBoton.ELEGIDO_OK
    elegido -> EstadoBoton.ELEGIDO_MAL
    correcto -> EstadoBoton.CORRECTO_NO_ELEGIDO
    else -> EstadoBoton.INACTIVO
}

@Composable
internal fun BotonRespuesta(
    texto: String, subtitulo: String?, color: Color, estado: EstadoBoton,
    modifier: Modifier = Modifier, onClick: () -> Unit,
) {
    val forma = RoundedCornerShape(40.dp)
    val aro = MaterialTheme.colorScheme.onSurface
    // El borde de la respuesta correcta no elegida «late» para llamar la atención.
    val latido = rememberInfiniteTransition(label = "latido")
    val alfaLatido by latido.animateFloat(
        initialValue = 0.25f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "alfa",
    )
    val borde = when (estado) {
        EstadoBoton.ELEGIDO_OK -> Modifier.border(3.dp, aro, forma)
        EstadoBoton.CORRECTO_NO_ELEGIDO -> Modifier.border(3.dp, aro.copy(alpha = alfaLatido), forma)
        else -> Modifier.border(3.dp, Color.Transparent, forma)
    }
    val alfaFondo = when (estado) {
        EstadoBoton.NORMAL, EstadoBoton.ELEGIDO_OK, EstadoBoton.CORRECTO_NO_ELEGIDO -> 1f
        EstadoBoton.ELEGIDO_MAL -> 0.45f
        EstadoBoton.INACTIVO -> 0.18f
    }
    val alfaTexto = if (estado == EstadoBoton.INACTIVO) 0.45f else 1f
    Box(modifier) {
        Box(borde.padding(4.dp)) {
            Button(
                onClick = onClick,
                enabled = estado == EstadoBoton.NORMAL,
                shape = forma,
                colors = ButtonDefaults.buttonColors(
                    containerColor = color, contentColor = Color.White,
                    disabledContainerColor = color.copy(alpha = alfaFondo),
                    disabledContentColor = Color.White.copy(alpha = alfaTexto),
                ),
                contentPadding = PaddingValues(horizontal = 4.dp, vertical = 8.dp),
                modifier = Modifier.fillMaxWidth().heightIn(min = 72.dp),
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        texto, fontSize = 22.sp, fontWeight = FontWeight.Bold,
                        textDecoration = if (estado == EstadoBoton.ELEGIDO_MAL) TextDecoration.LineThrough else null,
                    )
                    if (subtitulo != null) Text(subtitulo, fontSize = 11.sp, lineHeight = 13.sp, textAlign = TextAlign.Center)
                }
            }
        }
        // Insignia: ✓ si la opción es correcta (elegida o no), ✕ si es la elección equivocada.
        val insignia = when (estado) {
            EstadoBoton.ELEGIDO_OK, EstadoBoton.CORRECTO_NO_ELEGIDO -> "✓" to VERDE
            EstadoBoton.ELEGIDO_MAL -> "✕" to ROJO
            else -> null
        }
        if (insignia != null) {
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .size(28.dp)
                    .background(Color.White, CircleShape)
                    .border(2.dp, insignia.second, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(insignia.first, color = insignia.second, fontWeight = FontWeight.Black, fontSize = 16.sp)
            }
        }
    }
}

@Composable
internal fun Revelacion(
    actual: Iniciativa, todas: List<Iniciativa>, acierto: Boolean, verDetalle: Boolean,
    /** Partido por el que se ha preguntado (V/F) o el elegido (adivina). */
    elegido: Partido? = null,
    onToggle: () -> Unit,
) {
    val t = LocalTextos.current
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = (if (acierto) VERDE else ROJO).copy(alpha = 0.15f)),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                t.cabecera(acierto, elegido, actual),
                style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                color = if (acierto) VERDE else ROJO,
            )
            Text(
                if (actual.partido.nombre == actual.partido.sigla) "${actual.partido.sigla} — ${t.programa(actual.partido)}"
                else "${actual.partido.nombre} (${actual.partido.sigla}) — ${t.programa(actual.partido)}",
                style = MaterialTheme.typography.bodyMedium,
            )
            Text(
                t.medida(actual.numero, actual.pagina, actual.seccion),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (actual.coincidencias.isNotEmpty()) Coincidencias(actual, todas)
            TextButton(onClick = onToggle, contentPadding = PaddingValues(0.dp)) {
                Text(if (verDetalle) t.ocultarTexto else t.verTexto)
            }
            if (verDetalle) {
                if (LocalVerEsencial.current && actual.esencial.isNotBlank()) {
                    Text(
                        if (actual.original.isNotBlank()) t.tituloEnProgramaTraducido else t.tituloEnPrograma,
                        style = MaterialTheme.typography.labelLarge,
                    )
                    Text(actual.titulo, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                }
                if (actual.original.isNotBlank()) {
                    Text(t.textoOriginalCatalan, style = MaterialTheme.typography.labelLarge)
                    Text(actual.original, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                }
                if (actual.descripcion.isNotBlank()) Text(actual.descripcion, style = MaterialTheme.typography.bodyMedium)
                else if (actual.original.isBlank()) Text(t.sinDetalle, fontStyle = FontStyle.Italic)
            }
        }
    }
}

@Composable
private fun Coincidencias(actual: Iniciativa, todas: List<Iniciativa>) {
    val t = LocalTextos.current
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
                    t.compartidaCon(quienes),
                    style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold,
                )
                iguales.forEach { CoincidenciaFila(it, todas) }
            }
            if (parecidas.isNotEmpty()) {
                Text(t.parecidas, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
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
            LocalTextos.current.medidaCorta(c.partido, c.numero),
            style = MaterialTheme.typography.labelMedium, color = colorDe(c.partido), fontWeight = FontWeight.Bold,
        )
        Text("«${otra?.texto() ?: c.resumen}»", style = MaterialTheme.typography.bodyMedium)
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
    val t = LocalTextos.current

    Text(
        t.tituloResultado(partida.modo, partida.partido),
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
                t.mensaje(pct),
                style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center,
            )
            Text(
                when {
                    nuevoRecord -> t.nuevoRecord(recordAnterior)
                    recordAnterior >= 0 -> t.record(maxOf(recordAnterior, aciertos), total)
                    else -> t.primeraPartida
                },
                style = MaterialTheme.typography.bodyMedium,
                color = if (nuevoRecord) VERDE else MaterialTheme.colorScheme.onSurfaceVariant,
                fontWeight = if (nuevoRecord) FontWeight.Bold else FontWeight.Normal,
            )
        }
    }

    Button(onClick = onOtra, modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp)) { Text(t.jugarOtra, fontSize = 16.sp) }
    OutlinedButton(onClick = onMenu, modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp)) { Text(t.menu) }

    val compartidas = partida.preguntas.count { it.compartida }
    if (compartidas > 0) {
        Text(
            t.compartidasPartida(compartidas, total),
            style = MaterialTheme.typography.bodyMedium,
        )
    }
    Text(t.repaso, style = MaterialTheme.typography.titleMedium)
    partida.preguntas.forEachIndexed { i, ini ->
        val ok = partida.resultados.getOrNull(i) == true
        Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(if (ok) "✓" else "✗", color = if (ok) VERDE else ROJO, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Column(Modifier.weight(1f)) {
                Text(ini.texto(), style = MaterialTheme.typography.bodyMedium, maxLines = 3, overflow = TextOverflow.Ellipsis)
                Text(
                    t.medidaCorta(ini.partido, ini.numero) +
                        (if (ini.compartida) "  " + t.tambien((ini.partidosValidos - ini.partido).joinToString(", ") { it.sigla }) else ""),
                    style = MaterialTheme.typography.labelMedium, color = colorDe(ini.partido), fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}
